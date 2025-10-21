import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';

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

  static Future<String?> show({
    required BuildContext context,
    required DateTime day,
    required UserProfile userProfile,
    required ShiftCycleCalculator shiftCycleCalculator,
    required List<CalendarEntry> allEntries,
  }) {
    final normalizedDay = DateUtils.dateOnly(day);
    CalendarEntry? entryForDay;
    for (final entry in allEntries) {
      if (DateUtils.isSameDay(entry.date, normalizedDay)) {
        if (entryForDay == null || entry.date.isAfter(entryForDay.date)) {
          entryForDay = entry;
        }
      }
    }

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
  late final String _initialNote;

  @override
  void initState() {
    super.initState();
    _initialNote = widget.entry?.generalNote?.trim() ?? '';
    _noteController = TextEditingController(text: _initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                      label: Text('Zdarzeń: ${widget.entry?.events.length ?? 0}'),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    if ((widget.entry?.scheduledHours ?? 0) > 0)
                      Chip(
                        label: Text('Plan: ${_formatHours(widget.entry!.scheduledHours)}'),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Zdarzenia',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildEventsSection(theme, onShiftColor),
                if ((widget.entry?.incidents.length ?? 0) > 0) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Wyjazdy',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildIncidentsSection(theme),
                ],
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
                        if (trimmed == _initialNote) {
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

  Widget _buildEventsSection(ThemeData theme, Color onShiftColor) {
    final entry = widget.entry;
    if (entry == null || entry.events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Brak zdarzeń dla tego dnia.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: entry.events.length,
        itemBuilder: (context, index) {
          final event = entry.events[index];
          final label = _eventLabel(event);
          final detailLines = _eventInfoLines(event, entry);
          final note = event.note?.trim();

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
                if (detailLines.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      detailLines.join(' • '),
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

  Widget _buildIncidentsSection(ThemeData theme) {
    final entry = widget.entry;
    if (entry == null || entry.incidents.isEmpty) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: entry.incidents.length,
        itemBuilder: (context, index) {
          final incident = entry.incidents[index];
          final label = _incidentLabel(incident.category);
          final timeLabel = DateFormat.Hm('pl_PL').format(incident.timestamp);
          final note = incident.note?.trim();

          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            leading: const Icon(Icons.fire_truck, size: 20),
            title: Text(label, style: theme.textTheme.titleSmall),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Godzina: $timeLabel', style: theme.textTheme.bodySmall),
                if (note != null && note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(note, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
      ),
    );
  }

  String _eventLabel(DayEvent event) {
    switch (event.type) {
      case EventType.worked:
        return 'Przepracowana służba';
      case EventType.delegation:
        return 'Delegacja';
      case EventType.bloodDonation:
        return 'Oddanie krwi';
      case EventType.vacationStandard:
        return 'Urlop wypoczynkowy';
      case EventType.vacationAdditional:
        return 'Urlop dodatkowy';
      case EventType.sickLeave80:
        return 'Zwolnienie lekarskie 80%';
      case EventType.sickLeave100:
        return 'Zwolnienie lekarskie 100%';
      case EventType.dayOff:
        return 'Dzień wolny za służbę';
      case EventType.custom:
        return event.customDetails?.name ?? 'Zdarzenie niestandardowe';
      case EventType.overtimeOffDay:
        return 'Praca w dniu wolnym';
    }
  }

  List<String> _eventInfoLines(DayEvent event, CalendarEntry entry) {
    final info = <String>[];

    if (entry.scheduledHours > 0) {
      info.add('Plan: ${_formatHours(entry.scheduledHours)}');
    }

    info.add('Zdarzenie: ${_formatHours(event.hours)}');

    final overtime = entry.overtimeHours;
    if (overtime > 0) {
      info.add('Nadgodziny: ${_formatHours(overtime)}');
    }

    final undertime = entry.undertimeHours;
    if (undertime > 0) {
      info.add('Niewyrobione: ${_formatHours(undertime)}');
    }

    if (_eventBlocksSchedule(event)) {
      info.add('Zastępuje służbę');
    } else if (entry.hasScheduledHours && event.type == EventType.worked) {
      info.add('Służba z grafiku');
    } else if (!entry.hasScheduledHours && event.type == EventType.overtimeOffDay) {
      info.add('Dzień wolny w grafiku');
    }

    return info;
  }

  bool _eventBlocksSchedule(DayEvent event) {
    switch (event.type) {
      case EventType.vacationStandard:
      case EventType.vacationAdditional:
      case EventType.sickLeave80:
      case EventType.sickLeave100:
      case EventType.dayOff:
      case EventType.delegation:
      case EventType.bloodDonation:
        return true;
      case EventType.custom:
        return event.hours > 0;
      default:
        return false;
    }
  }

  String _incidentLabel(IncidentCategory category) {
    switch (category) {
      case IncidentCategory.fire:
        return 'Pożar';
      case IncidentCategory.localHazard:
        return 'Miejscowe zagrożenie';
      case IncidentCategory.falseAlarm:
        return 'Alarm fałszywy';
    }
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble() ? '${hours.toInt()} h' : '${hours.toStringAsFixed(1)} h';
  }
}
