import 'package:iskra/features/calendar/models/calendar_entry.dart';

/// Editable representation of a [DayEvent] used in day details workflow.
class EditableDayEvent {
  EditableDayEvent({
    required this.type,
    required this.hours,
    this.note,
    this.customName,
    this.customPayout,
  });

  factory EditableDayEvent.fromDomain(DayEvent event) {
    return EditableDayEvent(
      type: event.type,
      hours: event.hours,
      note: event.note,
      customName: event.customDetails?.name,
      customPayout: event.customDetails?.payoutPercentage,
    );
  }

  DayEvent toDomain() {
    return DayEvent(
      type: type,
      hours: hours,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      customDetails:
          type == EventType.customAbsence &&
                  customName != null &&
                  customName!.trim().isNotEmpty &&
                  customPayout != null
              ? CustomAbsenceDetails(
                  name: customName!.trim(),
                  payoutPercentage: customPayout!.clamp(0, 200),
                )
              : null,
    );
  }

  EventType type;
  double hours;
  String? note;
  String? customName;
  int? customPayout;
}
