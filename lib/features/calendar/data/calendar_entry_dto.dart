import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class CalendarEntryDto {
  CalendarEntryDto({
    required this.id,
    required this.date,
    required this.entryType,
    required this.scheduledHours,
    this.actualHours,
    this.vacationHoursDeducted,
    this.customDetails,
    this.notes,
  });

  final String id;
  final DateTime date;
  final EntryType entryType;
  final double scheduledHours;
  final double? actualHours;
  final double? vacationHoursDeducted;
  final CustomAbsenceDetails? customDetails;
  final String? notes;

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

    final entryType = _parseEntryType(data['entryType'] as String?);
    final legacyHours = (data['hours'] as num?)?.toDouble();

    final customData = data['customDetails'] as Map<String, dynamic>?;
    CustomAbsenceDetails? customDetails;
    if (customData != null) {
      final name = customData['name'] as String?;
      final payout = customData['payoutPercentage'] as num?;
      if (name != null && payout != null) {
        customDetails = CustomAbsenceDetails(
          name: name,
          payoutPercentage: payout.toInt(),
        );
      }
    }

    final scheduled = (data['scheduledHours'] as num?)?.toDouble();
    final actual = (data['actualHours'] as num?)?.toDouble();
    final vacation = (data['vacationHoursDeducted'] as num?)?.toDouble();
    final rawNotes = data['notes'] as String?;
    final trimmedNotes = rawNotes?.trim();

    return CalendarEntryDto(
      id: snapshot.id,
      date: timestamp.toDate(),
      entryType: entryType,
      scheduledHours: scheduled ?? legacyHours ?? _defaultScheduledHours(entryType),
      actualHours: _resolveActualHours(entryType, actual, legacyHours),
      vacationHoursDeducted: _resolveVacationHours(entryType, vacation, legacyHours),
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      customDetails: customDetails,
    );
  }

  factory CalendarEntryDto.fromDomain(CalendarEntry entry) {
    final trimmedNotes = entry.notes?.trim();
    return CalendarEntryDto(
      id: entry.id,
      date: entry.date,
      entryType: entry.entryType,
      scheduledHours: entry.scheduledHours,
      actualHours: entry.actualHours,
      vacationHoursDeducted: entry.vacationHoursDeducted,
      notes: (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes,
      customDetails: entry.customDetails,
    );
  }

  CalendarEntry toDomain() {
    return CalendarEntry(
      id: id,
      date: date,
      entryType: entryType,
      scheduledHours: scheduledHours,
      actualHours: actualHours,
      vacationHoursDeducted: vacationHoursDeducted,
      notes: notes,
      customDetails: customDetails,
    );
  }

  Map<String, dynamic> toFirestore({bool includeSentinels = true}) {
    final trimmedNotes = notes?.trim();
    final data = <String, dynamic>{
      'date': Timestamp.fromDate(date),
      'entryType': entryType.name,
      'scheduledHours': scheduledHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (actualHours != null) {
      data['actualHours'] = actualHours;
    } else if (includeSentinels) {
      data['actualHours'] = FieldValue.delete();
    }

    if (vacationHoursDeducted != null) {
      data['vacationHoursDeducted'] = vacationHoursDeducted;
    } else if (includeSentinels) {
      data['vacationHoursDeducted'] = FieldValue.delete();
    }

    if (trimmedNotes != null && trimmedNotes.isNotEmpty) {
      data['notes'] = trimmedNotes;
    } else if (includeSentinels) {
      data['notes'] = FieldValue.delete();
    }

    if (customDetails != null) {
      data['customDetails'] = {
        'name': customDetails!.name,
        'payoutPercentage': customDetails!.payoutPercentage,
      };
    } else if (includeSentinels) {
      data['customDetails'] = FieldValue.delete();
    }

    return data;
  }
}

EntryType _parseEntryType(String? raw) {
  if (raw == null || raw.isEmpty) {
    return EntryType.custom;
  }
  if (raw == 'overtime') {
    return EntryType.worked;
  }
  for (final value in EntryType.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return EntryType.custom;
}

double _defaultScheduledHours(EntryType type) {
  switch (type) {
    case EntryType.overtimeOffDay:
    case EntryType.custom:
      return 0;
    default:
      return 24;
  }
}

double? _resolveActualHours(EntryType type, double? actual, double? legacy) {
  if (actual != null) {
    return actual;
  }
  if (legacy == null) {
    return null;
  }
  if (type == EntryType.worked || type == EntryType.overtimeOffDay) {
    return legacy;
  }
  return null;
}

double? _resolveVacationHours(EntryType type, double? vacation, double? legacy) {
  if (vacation != null) {
    return vacation;
  }
  if (legacy == null) {
    return null;
  }
  if (type == EntryType.vacationStandard || type == EntryType.vacationAdditional) {
    return legacy;
  }
  return null;
}
