import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';

class CalendarEntryDto {
  CalendarEntryDto({
    required this.id,
    required this.date,
    required this.scheduledHours,
    List<DayEvent> events = const [],
    List<IncidentEntry> incidents = const [],
    this.generalNote,
  }) : events = List.unmodifiable(events),
       incidents = List.unmodifiable(incidents);

  final String id;
  final DateTime date;
  final double scheduledHours;
  final List<DayEvent> events;
  final List<IncidentEntry> incidents;
  final String? generalNote;

  factory CalendarEntryDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Calendar entry document ${snapshot.id} has no data');
    }

    final timestamp = data['date'] as Timestamp?;
    if (timestamp == null) {
      throw StateError('Calendar entry ${snapshot.id} is missing "date"');
    }

    final scheduled = _resolveScheduledHours(data);
    final events = _parseEvents(data['events'], data, scheduled);
    final incidents = _parseIncidents(data['incidents']);
    final rawNote = data['notes'] as String?;
    final trimmedNote = rawNote?.trim();

    return CalendarEntryDto(
      id: _resolveDocumentId(snapshot.id, timestamp.toDate()),
      date: timestamp.toDate(),
      scheduledHours: scheduled,
      events: events,
      incidents: incidents,
      generalNote: (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
    );
  }

  factory CalendarEntryDto.fromDomain(CalendarEntry entry) {
    final note = entry.generalNote?.trim();
    return CalendarEntryDto(
      id: entry.id,
      date: entry.date,
      scheduledHours: entry.scheduledHours,
      events: entry.events,
      incidents: entry.incidents,
      generalNote: (note == null || note.isEmpty) ? null : note,
    );
  }

  CalendarEntry toDomain() {
    return CalendarEntry(
      id: id,
      date: date,
      scheduledHours: scheduledHours,
      events: events,
      incidents: incidents,
      generalNote: generalNote,
    );
  }

  Map<String, dynamic> toFirestore({bool includeSentinels = true}) {
    final data = <String, dynamic>{
      'date': Timestamp.fromDate(date),
      'scheduledHours': scheduledHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (events.isNotEmpty) {
      data['events'] = events.map(_serializeEvent).toList();
    } else if (includeSentinels) {
      data['events'] = FieldValue.delete();
    }

    if (incidents.isNotEmpty) {
      data['incidents'] = incidents.map(_serializeIncident).toList();
    } else if (includeSentinels) {
      data['incidents'] = FieldValue.delete();
    }

    if (generalNote != null && generalNote!.trim().isNotEmpty) {
      data['notes'] = generalNote!.trim();
    } else if (includeSentinels) {
      data['notes'] = FieldValue.delete();
    }

    if (includeSentinels) {
      data['entryType'] = FieldValue.delete();
      data['actualHours'] = FieldValue.delete();
      data['vacationHoursDeducted'] = FieldValue.delete();
      data['customDetails'] = FieldValue.delete();
    }

    return data;
  }
}

double _resolveScheduledHours(Map<String, dynamic> data) {
  final scheduled = (data['scheduledHours'] as num?)?.toDouble();
  if (scheduled != null) {
    return scheduled;
  }
  final legacyHours = (data['hours'] as num?)?.toDouble();
  if (legacyHours != null) {
    return legacyHours;
  }
  final legacyEntryType = data['entryType'] as String?;
  if (legacyEntryType == null || legacyEntryType == 'overtimeOffDay') {
    return 0;
  }
  return legacyEntryType == 'scheduledService' ? 24 : 0;
}

List<DayEvent> _parseEvents(
  Object? rawEvents,
  Map<String, dynamic> data,
  double scheduledHours,
) {
  if (rawEvents is List) {
    final parsed = rawEvents
        .map(
          (event) => event is Map<String, dynamic> ? _parseEvent(event) : null,
        )
        .whereType<DayEvent>()
        .toList();
    if (parsed.isEmpty) {
      return const [];
    }
    return List.unmodifiable(parsed);
  }

  final legacyTypeRaw = data['entryType'] as String?;
  if (legacyTypeRaw == null || legacyTypeRaw == 'scheduledService') {
    return const [];
  }
  final legacyType = _parseLegacyEventType(legacyTypeRaw);
  if (legacyType == null) {
    return const [];
  }

  final hours = _resolveLegacyEventHours(data, scheduledHours);
  final note = (data['notes'] as String?)?.trim();
  final customDetails = _parseCustomDetails(
    data['customDetails'] as Map<String, dynamic>?,
  );

  return List.unmodifiable([
    DayEvent(
      type: legacyType,
      hours: hours,
      customDetails: customDetails,
      note: (note == null || note.isEmpty) ? null : note,
    ),
  ]);
}

DayEvent? _parseEvent(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  final typeRaw = data['type'] as String?;
  final type = _parseEventType(typeRaw);
  if (type == null) {
    return null;
  }
  final hours = (data['hours'] as num?)?.toDouble() ?? 0;
  final noteRaw = data['note'] as String?;
  final note = noteRaw?.trim();
  final customDetails = _parseCustomDetails(
    data['customDetails'] as Map<String, dynamic>?,
  );

  return DayEvent(
    type: type,
    hours: hours < 0 ? 0 : hours,
    customDetails: customDetails,
    note: (note == null || note.isEmpty) ? null : note,
  );
}

CustomAbsenceDetails? _parseCustomDetails(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  final name = data['name'] as String?;
  final payout = data['payoutPercentage'] as num?;
  if (name == null || payout == null) {
    return null;
  }
  return CustomAbsenceDetails(name: name, payoutPercentage: payout.toInt());
}

double _resolveLegacyEventHours(
  Map<String, dynamic> data,
  double scheduledHours,
) {
  final actual = (data['actualHours'] as num?)?.toDouble();
  if (actual != null) {
    return actual;
  }
  final vacation = (data['vacationHoursDeducted'] as num?)?.toDouble();
  if (vacation != null && vacation > 0) {
    return vacation;
  }
  final legacyHours = (data['hours'] as num?)?.toDouble();
  if (legacyHours != null) {
    return legacyHours;
  }
  return scheduledHours;
}

List<IncidentEntry> _parseIncidents(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final incidents = <IncidentEntry>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) {
      continue;
    }
    final incident = _parseIncident(item);
    if (incident != null) {
      incidents.add(incident);
    }
  }
  if (incidents.isEmpty) {
    return const [];
  }
  return List.unmodifiable(incidents);
}

IncidentEntry? _parseIncident(Map<String, dynamic> data) {
  final id = data['id'] as String?;
  final categoryRaw = data['category'] as String?;
  final timestampRaw = data['timestamp'];
  if (id == null || categoryRaw == null || timestampRaw is! Timestamp) {
    return null;
  }
  final category = _parseIncidentCategory(categoryRaw);
  if (category == null) {
    return null;
  }
  final noteRaw = data['note'] as String?;
  final note = noteRaw?.trim();
  return IncidentEntry(
    id: id,
    category: category,
    timestamp: timestampRaw.toDate(),
    note: (note == null || note.isEmpty) ? null : note,
  );
}

Map<String, dynamic> _serializeEvent(DayEvent event) {
  return {
    'type': event.type.name,
    'hours': event.hours,
    if (event.note != null && event.note!.trim().isNotEmpty)
      'note': event.note!.trim(),
    if (event.customDetails != null)
      'customDetails': {
        'name': event.customDetails!.name,
        'payoutPercentage': event.customDetails!.payoutPercentage,
      },
  };
}

Map<String, dynamic> _serializeIncident(IncidentEntry incident) {
  return {
    'id': incident.id,
    'category': incident.category.name,
    'timestamp': Timestamp.fromDate(incident.timestamp),
    if (incident.note != null && incident.note!.trim().isNotEmpty)
      'note': incident.note!.trim(),
  };
}

EventType? _parseEventType(String? raw) {
  if (raw == null) {
    return null;
  }
  switch (raw) {
    case 'worked':
      return EventType.overtimeWorked;
    case 'vacationStandard':
      return EventType.vacationRegular;
    case 'custom':
      return EventType.customAbsence;
    case 'dayOff':
      return EventType.otherAbsence;
    case 'overtimeOffDay':
      return EventType.overtimeTimeOff;
  }
  for (final value in EventType.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return null;
}

EventType? _parseLegacyEventType(String raw) {
  switch (raw) {
    case 'delegation':
      return EventType.delegation;
    case 'bloodDonation':
      return EventType.bloodDonation;
    case 'vacationStandard':
      return EventType.vacationRegular;
    case 'vacationAdditional':
      return EventType.vacationAdditional;
    case 'sickLeave80':
      return EventType.sickLeave80;
    case 'sickLeave100':
      return EventType.sickLeave100;
    case 'custom':
      return EventType.customAbsence;
    case 'dayOff':
      return EventType.otherAbsence;
    case 'overtimeOffDay':
      return EventType.overtimeTimeOff;
    default:
      return null;
  }
}

IncidentCategory? _parseIncidentCategory(String raw) {
  for (final value in IncidentCategory.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return null;
}

String _resolveDocumentId(String rawId, DateTime date) {
  final normalized = _formatDateId(date);
  if (rawId == normalized) {
    return rawId;
  }
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(rawId);
  if (match != null) {
    return match.group(1)!;
  }
  return normalized;
}

String _formatDateId(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
