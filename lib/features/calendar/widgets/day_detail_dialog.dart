import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_detail_header.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_event_editor.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_note_section.dart';
import 'package:iskra/features/calendar/widgets/day_detail/day_schedule_hours_picker.dart';

class DayDetailDialogResult {
  const DayDetailDialogResult({
    required this.events,
    required this.generalNote,
    this.scheduledHours,
  });

  final List<DayEvent> events;
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
  double? _scheduledHours;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.entry?.generalNote ?? '',
    );
    _events = (widget.entry?.events ?? const <DayEvent>[])
        .map(EditableDayEvent.fromDomain)
        .toList();
    _scheduledHours = widget.isScheduled
        ? (widget.entry?.scheduledHours ?? 0)
        : null;
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
                          onChanged: (value) =>
                              setState(() => _scheduledHours = value),
                        ),
                        const SizedBox(height: 24),
                      ],
                      DayEventEditor(
                        events: _events,
                        onChanged: (updated) =>
                            setState(() => _events = updated),
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

  void _submit() {
    final events = _events.map((event) => event.toDomain()).toList();
    final note = _noteController.text.trim();
    final scheduledHours = widget.isScheduled ? (_scheduledHours ?? 0) : null;
    Navigator.of(context).pop(
      DayDetailDialogResult(
        events: events,
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
