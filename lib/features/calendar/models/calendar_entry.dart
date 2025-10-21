import 'package:iskra/features/calendar/models/incident_entry.dart';

const Object _undefined = Object();

enum EventType {
  worked,
  delegation,
  bloodDonation,
  vacationStandard,
  vacationAdditional,
  sickLeave80,
  sickLeave100,
  dayOff,
  custom,
  overtimeOffDay,
}

class CustomAbsenceDetails {
  CustomAbsenceDetails({required this.name, required this.payoutPercentage});

  final String name;
  final int payoutPercentage;
}

class DayEvent {
  const DayEvent({
    required this.type,
    required this.hours,
    this.customDetails,
    this.note,
  }) : assert(hours >= 0, 'hours must be non-negative');

  final EventType type;
  final double hours;
  final CustomAbsenceDetails? customDetails;
  final String? note;

  DayEvent copyWith({
    EventType? type,
    double? hours,
    Object? customDetails = _undefined,
    Object? note = _undefined,
  }) {
    return DayEvent(
      type: type ?? this.type,
      hours: hours ?? this.hours,
      customDetails: customDetails == _undefined
          ? this.customDetails
          : customDetails as CustomAbsenceDetails?,
      note: note == _undefined ? this.note : note as String?,
    );
  }
}

class CalendarEntry {
  CalendarEntry({
    required this.id,
    required this.date,
    required this.scheduledHours,
    List<DayEvent> events = const [],
    List<IncidentEntry> incidents = const [],
    this.generalNote,
  })  : assert(scheduledHours >= 0, 'scheduledHours must be non-negative'),
        events = List.unmodifiable(events),
        incidents = List.unmodifiable(incidents);

  final String id;
  final DateTime date;
  final double scheduledHours;
  final List<DayEvent> events;
  final List<IncidentEntry> incidents;
  final String? generalNote;

  CalendarEntry copyWith({
    String? id,
    DateTime? date,
    double? scheduledHours,
    List<DayEvent>? events,
    List<IncidentEntry>? incidents,
    Object? generalNote = _undefined,
  }) {
    return CalendarEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      scheduledHours: scheduledHours ?? this.scheduledHours,
      events: events == null ? this.events : List.unmodifiable(events),
      incidents: incidents == null ? this.incidents : List.unmodifiable(incidents),
      generalNote:
          generalNote == _undefined ? this.generalNote : generalNote as String?,
    );
  }

  bool get hasScheduledHours => scheduledHours > 0;

  double get baseHoursWorked {
    final worked = _sumHours({EventType.worked, EventType.delegation, EventType.bloodDonation});
    if (!hasScheduledHours) {
      return worked;
    }
    return worked > scheduledHours ? scheduledHours : worked;
  }

  double get overtimeHours {
    final workedHours = _sumHours({EventType.worked});
    final overtimeOffDayHours = _sumHours({EventType.overtimeOffDay});
    if (hasScheduledHours) {
      return workedHours > scheduledHours ? workedHours - scheduledHours : 0;
    }
    return workedHours + overtimeOffDayHours;
  }

  double get undertimeHours {
    if (!hasScheduledHours) {
      return 0;
    }
    final covered = _sumHours({
      EventType.worked,
      EventType.delegation,
      EventType.bloodDonation,
      EventType.vacationStandard,
      EventType.vacationAdditional,
      EventType.sickLeave80,
      EventType.sickLeave100,
      EventType.dayOff,
      EventType.custom,
    });
    final deficit = scheduledHours - covered;
    return deficit > 0 ? deficit : 0;
  }

  int get totalIncidents => incidents.length;

  int incidentsByCategory(IncidentCategory category) {
    return incidents.where((incident) => incident.category == category).length;
  }

  double _sumHours(Set<EventType> types) {
    return events
        .where((event) => types.contains(event.type))
        .fold<double>(0, (sum, event) => sum + event.hours);
  }
}