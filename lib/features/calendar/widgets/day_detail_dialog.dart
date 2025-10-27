import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/quick_status_validator.dart';
import 'package:iskra/features/calendar/widgets/day_detail/validation_conflict_dialog.dart';
import 'package:iskra/features/calendar/models/editable_day_event.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_detail_header.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_incidents_section.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_note_section.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_quick_status_section.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_schedule_hours_picker.dart';

class DayDetailDialogResult {
  const DayDetailDialogResult({
    required this.events,
    required this.incidents,
    required this.generalNote,
    this.scheduledHours,
  });

  final List<DayEvent> events;
  final List<IncidentEntry> incidents;
  final String generalNote;
  final double? scheduledHours;
}

class DayDetailDialog extends StatefulWidget {
  const DayDetailDialog({
    super.key,
    required this.day,
    required this.entry,
    required this.shiftColor,
    required this.shiftId,
    required this.isScheduled,
  });

  final DateTime day;
  final CalendarEntry? entry;
  final Color shiftColor;
  final int shiftId;
  final bool isScheduled;

  static Future<DayDetailDialogResult?> show({
    required BuildContext context,
    required DateTime day,
    required UserProfile userProfile,
    required ShiftCycleCalculator shiftCycleCalculator,
    required List<CalendarEntry> allEntries,
  }) {
    final normalizedDay = DateUtils.dateOnly(day);
    final entryForDay = allEntries
        .where((entry) => DateUtils.isSameDay(entry.date, normalizedDay))
        .sorted((a, b) => b.date.compareTo(a.date))
        .firstOrNull;

    final sortedHistory = List<ShiftAssignment>.from(userProfile.shiftHistory)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final isScheduled = shiftCycleCalculator.isScheduledDayForUser(
      normalizedDay,
      sortedHistory,
    );
    final shiftId = shiftCycleCalculator.shiftOn(normalizedDay);
    final shiftColor = userProfile.shiftColorPalette.colorForShift(shiftId);

    return showDialog<DayDetailDialogResult>(
      context: context,
      builder: (_) => DayDetailDialog(
        day: normalizedDay,
        entry: entryForDay,
        shiftColor: shiftColor,
        shiftId: shiftId,
        isScheduled: isScheduled,
      ),
    );
  }

  @override
  State<DayDetailDialog> createState() => _DayDetailDialogState();
}

class _DayDetailDialogState extends State<DayDetailDialog> {
  late final TextEditingController _noteController;
  late List<EditableDayEvent> _events;
  late List<IncidentEntry> _incidents;
  late Map<EventType, double> _quickSelections;
  double? _scheduledHours;

  static const Set<EventType> _quickEventTypes = {
    EventType.overtimeWorked,
    EventType.delegation,
    EventType.bloodDonation,
    EventType.vacationRegular,
    EventType.vacationAdditional,
    EventType.sickLeave80,
    EventType.sickLeave100,
    EventType.paidAbsence,
    EventType.overtimeTimeOff,
    EventType.homeDuty,
  };

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.entry?.generalNote ?? '',
    );
    _events = <EditableDayEvent>[];
    _incidents = List<IncidentEntry>.from(
      widget.entry?.incidents ?? const <IncidentEntry>[],
    )
      ..sort(_compareIncidents);
    _quickSelections = <EventType, double>{};

    for (final event in widget.entry?.events ?? const <DayEvent>[]) {
      final hasExtraData =
          event.note != null && event.note!.trim().isNotEmpty;
      if (_quickEventTypes.contains(event.type) && !hasExtraData) {
        _quickSelections[event.type] = event.hours;
      } else {
        _events.add(EditableDayEvent.fromDomain(event));
      }
    }
    _scheduledHours = widget.isScheduled
        ? (widget.entry?.scheduledHours ?? 0)
        : null;
    _applyScheduleConstraints();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMMM yyyy', 'pl_PL').format(widget.day);
    final shiftLabel = 'Zmiana ${widget.shiftId}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DayDetailHeader(
                dayLabel: dateLabel,
                shiftLabel: shiftLabel,
                shiftColor: widget.shiftColor,
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isScheduled && _scheduledHours != null) ...[
                        DayScheduleHoursPicker(
                          value: _scheduledHours ?? 0,
                          onChanged: (value) => setState(() {
                            _scheduledHours = value;
                            _applyScheduleConstraints();
                          }),
                        ),
                        const SizedBox(height: 24),
                      ],
                      DayQuickStatusSection(
                        selections: _quickSelections,
                        scheduledHours: widget.isScheduled
                            ? _scheduledHours
                            : null,
                        onChanged: (updated) => setState(() {
                          _quickSelections = Map<EventType, double>.from(
                            updated,
                          );
                          _applyScheduleConstraints();
                        }),
                      ),
                      const SizedBox(height: 24),
                      DayIncidentsSection(
                        day: widget.day,
                        incidents: _incidents,
                        onChanged: (updated) => setState(() {
                          _incidents = List<IncidentEntry>.from(updated)
                            ..sort(_compareIncidents);
                        }),
                      ),
                      const SizedBox(height: 24),
                      DayNoteSection(controller: _noteController),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Zapisz zmiany'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _applyScheduleConstraints() {
    var sanitizedQuick = Map<EventType, double>.from(_quickSelections);
    var quickChanged = false;

    MapEntry<EventType, double>? selectedSickEntry;
    for (final entry in sanitizedQuick.entries) {
      if (_isSickLeave(entry.key)) {
        selectedSickEntry = entry;
        break;
      }
    }
    if (selectedSickEntry != null) {
      final preserved = <EventType, double>{
        selectedSickEntry.key: selectedSickEntry.value,
      };
      if (sanitizedQuick.length != preserved.length ||
          sanitizedQuick[selectedSickEntry.key] != selectedSickEntry.value) {
        quickChanged = true;
      }
      sanitizedQuick = preserved;
    }

    if (quickChanged) {
      _quickSelections = sanitizedQuick;
    }

    final sanitizedEvents = <EditableDayEvent>[];
    var eventsChanged = false;

    for (final event in _events) {
      final normalizedHours = event.hours.clamp(0, 48).toDouble();

      if (normalizedHours != event.hours) {
        eventsChanged = true;
      }
      sanitizedEvents.add(_cloneEvent(event, hours: normalizedHours));
    }

    if (eventsChanged) {
      _events = sanitizedEvents;
    }
  }

  EditableDayEvent _cloneEvent(
    EditableDayEvent source, {
    EventType? type,
    double? hours,
  }) {
    return EditableDayEvent(
      type: type ?? source.type,
      hours: hours ?? source.hours,
      note: source.note,
    );
  }

  bool _isSickLeave(EventType type) {
    return type == EventType.sickLeave80 || type == EventType.sickLeave100;
  }

  int _compareIncidents(IncidentEntry a, IncidentEntry b) {
    final aTime = a.timestamp;
    final bTime = b.timestamp;
    if (aTime == null && bTime == null) {
      return 0;
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    return aTime.compareTo(bTime);
  }

  void _submit() async {
    final validator = QuickStatusValidator();
    final conflicts = validator.validateSelections(
      selections: _quickSelections,
      scheduledHours: widget.isScheduled ? _scheduledHours : null,
    );

    if (conflicts.isNotEmpty) {
      await ValidationConflictDialog.show(context, conflicts: conflicts);
      return;
    }

    final combinedEvents = <DayEvent>[
      ..._events.map((event) => event.toDomain()),
      ..._quickSelections.entries.map(
        (entry) => DayEvent(type: entry.key, hours: entry.value),
      ),
    ];
    final note = _noteController.text.trim();
    final scheduledHours = widget.isScheduled ? (_scheduledHours ?? 0) : null;
    Navigator.of(context).pop(
      DayDetailDialogResult(
        events: combinedEvents,
        incidents: List<IncidentEntry>.from(_incidents),
        generalNote: note,
        scheduledHours: scheduledHours,
      ),
    );
  }
}

extension _IterableExtensions<T> on Iterable<T> {
  List<T> sorted(int Function(T a, T b) compare) => toList()..sort(compare);
  T? get firstOrNull => isEmpty ? null : first;
}
