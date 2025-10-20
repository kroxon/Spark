import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';

class DayDetailDialog extends StatefulWidget {
  const DayDetailDialog({
    super.key,
    required this.day,
    required this.entries,
    required this.shiftColor,
    required this.shiftId,
    required this.isScheduled,
  });

  final DateTime day;
  final List<CalendarEntry> entries;
  final Color shiftColor;
  final int shiftId;
  final bool isScheduled;

  static Future<String?> show({
    required BuildContext context,
    required DateTime day,
    required UserProfile userProfile,
    required ShiftCycleCalculator shiftCycleCalculator,
    required List<CalendarEntry> allEntries,
  }) {
    final normalizedDay = DateUtils.dateOnly(day);
    final entriesForDay = allEntries
        .where((entry) => DateUtils.isSameDay(entry.date, normalizedDay))
        .toList()
      ..sort((a, b) => a.entryType.index.compareTo(b.entryType.index));

    final sortedHistory = List<ShiftAssignment>.from(userProfile.shiftHistory)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final isScheduled = shiftCycleCalculator.isScheduledDayForUser(normalizedDay, sortedHistory);
    final assignment = shiftCycleCalculator.assignmentForDate(normalizedDay, sortedHistory);
    final shiftId = assignment?.shiftId ?? shiftCycleCalculator.shiftOn(normalizedDay);
    final shiftColor = userProfile.shiftColorPalette.colorForShift(shiftId);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => DayDetailDialog(
        day: normalizedDay,
        entries: entriesForDay,
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
  late final String _initialNote;

  @override
  void initState() {
    super.initState();
    _initialNote = _findInitialNote();
    _noteController = TextEditingController(text: _initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _findInitialNote() {
    for (final entry in widget.entries) {
      final note = entry.notes;
      if (note != null && note.trim().isNotEmpty) {
        return note;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEEE, d MMMM', 'pl_PL').format(widget.day);
    final yearLabel = DateFormat('yyyy', 'pl_PL').format(widget.day);
    final onShiftColor = ThemeData.estimateBrightnessForColor(widget.shiftColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  yearLabel,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text('Zmiana ${widget.shiftId}'),
                      backgroundColor: widget.shiftColor.withValues(alpha: 0.18),
                      avatar: CircleAvatar(
                        backgroundColor: widget.shiftColor,
                        child: Icon(
                          Icons.bolt,
                          color: onShiftColor,
                          size: 16,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(widget.isScheduled ? 'Dzień służby' : 'Dzień wolny'),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                    Chip(
                      label: Text('Wpisów: ${widget.entries.length}'),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Wpisy',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildEntriesSection(theme, onShiftColor),
                const SizedBox(height: 24),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notatka do tego dnia',
                    hintText: 'Dodaj komentarz lub ustalenia...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final trimmed = _noteController.text.trim();
                        if (trimmed == _initialNote.trim()) {
                          Navigator.of(context).pop(null);
                        } else {
                          Navigator.of(context).pop(trimmed);
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Zapisz notatkę'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesSection(ThemeData theme, Color onShiftColor) {
    if (widget.entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Brak wpisów dla tego dnia.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          final label = _entryTypeLabel(entry);
          final note = entry.notes?.trim();
          final info = _entryInfoLines(entry);

          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            leading: CircleAvatar(
              backgroundColor: widget.shiftColor,
              child: Icon(
                Icons.event_note,
                color: onShiftColor,
                size: 18,
              ),
            ),
            title: Text(label, style: theme.textTheme.titleSmall),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      info.join(' • '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
      ),
    );
  }

  String _entryTypeLabel(CalendarEntry entry) {
    switch (entry.entryType) {
      case EntryType.scheduledService:
        return 'Zaplanowana służba';
      case EntryType.vacationStandard:
        return 'Urlop wypoczynkowy';
      case EntryType.vacationAdditional:
        return 'Urlop dodatkowy';
      case EntryType.sickLeave80:
        return 'Zwolnienie lekarskie 80%';
      case EntryType.sickLeave100:
        return 'Zwolnienie lekarskie 100%';
      case EntryType.delegation:
        return 'Delegacja';
      case EntryType.bloodDonation:
        return 'Oddanie krwi';
      case EntryType.dayOff:
        return 'Dzień wolny za służbę';
      case EntryType.custom:
        return entry.customDetails?.name ?? 'Zdarzenie niestandardowe';
      case EntryType.worked:
        return 'Przepracowana służba';
      case EntryType.overtimeOffDay:
        return 'Praca w dniu wolnym';
    }
  }

  List<String> _entryInfoLines(CalendarEntry entry) {
    final info = <String>[];

    if (entry.scheduledHours > 0) {
      info.add('Plan: ${_formatHours(entry.scheduledHours)}');
    }

    if (entry.actualHours != null && entry.actualHours! >= 0) {
      info.add('Rzeczywiste: ${_formatHours(entry.actualHours!)}');
    }

    if (entry.vacationHoursDeducted != null && entry.vacationHoursDeducted! > 0) {
      info.add('Urlop: ${_formatHours(entry.vacationHoursDeducted!)}');
    }

    final base = entry.baseHoursWorked;
    final showBase = base > 0 &&
        !(entry.entryType == EntryType.scheduledService && base == entry.scheduledHours);
    if (showBase) {
      info.add('Norma: ${_formatHours(base)}');
    }

    final overtime = entry.overtimeHours;
    if (overtime > 0) {
      info.add('Nadgodziny: ${_formatHours(overtime)}');
    }

    final undertime = entry.undertimeHours;
    if (undertime > 0) {
      info.add('Niewyrobione: ${_formatHours(undertime)}');
    }

    if (_replacesSchedule(entry)) {
      info.add('Zastępuje służbę');
    } else if (entry.entryType == EntryType.scheduledService) {
      info.add('Służba z grafiku');
    } else if (entry.entryType == EntryType.overtimeOffDay) {
      info.add('Dzień wolny w grafiku');
    }

    return info;
  }

  bool _replacesSchedule(CalendarEntry entry) {
    switch (entry.entryType) {
      case EntryType.vacationStandard:
      case EntryType.vacationAdditional:
      case EntryType.sickLeave80:
      case EntryType.sickLeave100:
      case EntryType.delegation:
      case EntryType.bloodDonation:
      case EntryType.dayOff:
        return true;
      case EntryType.custom:
        return entry.scheduledHours > 0;
      default:
        return false;
    }
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble() ? '${hours.toInt()} h' : '${hours.toStringAsFixed(1)} h';
  }
}
