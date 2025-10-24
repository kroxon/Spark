import 'package:iskra/features/calendar/models/calendar_entry.dart';

/// Editable representation of a [DayEvent] used in day details workflow.
class EditableDayEvent {
  EditableDayEvent({
    required this.type,
    required this.hours,
    this.note,
  });

  factory EditableDayEvent.fromDomain(DayEvent event) {
    return EditableDayEvent(
      type: event.type,
      hours: event.hours,
      note: event.note,
    );
  }

  DayEvent toDomain() {
    return DayEvent(
      type: type,
      hours: hours,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
  }

  EventType type;
  double hours;
  String? note;
}
