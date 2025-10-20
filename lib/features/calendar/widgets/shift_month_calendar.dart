import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';

class ShiftMonthCalendar extends StatefulWidget {
  const ShiftMonthCalendar({
    super.key,
    required this.initialMonth,
    required this.userProfile,
    required this.entries,
    required this.shiftCycleCalculator,
    this.onDaySelected,
    this.onMonthChanged,
    this.showMonthNavigation = true,
    this.isEditing = false,
    this.onEditModeToggle,
    this.onAssignScheduledService,
  });

  final DateTime initialMonth;
  final UserProfile userProfile;
  final List<CalendarEntry> entries;
  final ShiftCycleCalculator shiftCycleCalculator;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged;
  final bool showMonthNavigation;
  final bool isEditing;
  final VoidCallback? onEditModeToggle;
  final Future<void> Function(DateTime day)? onAssignScheduledService;

  @override
  State<ShiftMonthCalendar> createState() => _ShiftMonthCalendarState();
}

class _ShiftMonthCalendarState extends State<ShiftMonthCalendar> {
  late DateTime _visibleMonth;
  late List<ShiftAssignment> _sortedShiftHistory;
  late Map<DateTime, List<CalendarEntry>> _entriesByDate;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _buildShiftHistory();
    _buildEntries();
  }

  @override
  void didUpdateWidget(covariant ShiftMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth.year != oldWidget.initialMonth.year ||
        widget.initialMonth.month != oldWidget.initialMonth.month) {
      _visibleMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    }

    if (!identical(widget.userProfile, oldWidget.userProfile) ||
        widget.userProfile.shiftHistory.length != oldWidget.userProfile.shiftHistory.length) {
      _buildShiftHistory();
    }

    if (!identical(widget.entries, oldWidget.entries) ||
        !listEquals(widget.entries, oldWidget.entries)) {
      _buildEntries();
    }
  }

  void _buildShiftHistory() {
    _sortedShiftHistory = List<ShiftAssignment>.from(widget.userProfile.shiftHistory)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  void _buildEntries() {
    _entriesByDate = <DateTime, List<CalendarEntry>>{};
    for (final entry in widget.entries) {
      final day = DateUtils.dateOnly(entry.date);
      final list = _entriesByDate.putIfAbsent(day, () => <CalendarEntry>[]);
      list.add(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerLabel = _polishMonthLabel(_visibleMonth);
    final weekdayLabels = _polishWeekdayLabels();
    final days = _daysInVisibleMonth();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, headerLabel),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: widget.isEditing
              ? _EditingBanner(
                  onExit: widget.onEditModeToggle,
                )
              : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdayLabels
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowCount = (days.length / 7).ceil();
              final cellWidth = constraints.maxWidth / 7;
              final cellHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight / rowCount
                  : 96.0;
              final columnWidths = <int, TableColumnWidth>{
                for (var i = 0; i < 7; i++) i: FixedColumnWidth(cellWidth),
              };
              return SizedBox.expand(
                child: Table(
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: _buildRows(days, theme, cellWidth, cellHeight),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, String headerLabel) {
    final header = _HeaderRow(
      title: headerLabel,
      isEditing: widget.isEditing,
      onEditToggle: widget.onEditModeToggle,
    );

    if (!widget.showMonthNavigation) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: header,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousMonth,
          ),
          Expanded(child: header),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildRows(List<DateTime> days, ThemeData theme, double cellWidth, double cellHeight) {
    final rows = <TableRow>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = days.sublist(i, i + 7);
      rows.add(
        TableRow(
          children: week.map((day) => _buildCell(day, theme, cellWidth, cellHeight)).toList(),
        ),
      );
    }
    return rows;
  }

  Widget _buildCell(DateTime day, ThemeData theme, double cellWidth, double cellHeight) {
    final colors = theme.colorScheme;
    final dateOnly = DateUtils.dateOnly(day);
    final isCurrentMonth = dateOnly.year == _visibleMonth.year && dateOnly.month == _visibleMonth.month;
    final isToday = DateUtils.isSameDay(DateTime.now(), dateOnly);
    final onDuty = widget.shiftCycleCalculator.isScheduledDayForUser(dateOnly, _sortedShiftHistory);
    final shiftOnDuty = widget.shiftCycleCalculator.shiftOn(dateOnly);
    final entries = _entriesByDate[dateOnly] ?? const <CalendarEntry>[];
    final hasEntry = entries.isNotEmpty;
    final plannedOff = onDuty && entries.any(_replacesScheduleOnCalendar);
    final hasScheduledService = entries.any((entry) => entry.entryType == EntryType.scheduledService);
    final dutyColor = widget.userProfile.shiftColorPalette.colorForShift(shiftOnDuty);

    Color backgroundColor;
    if (widget.isEditing && onDuty) {
      backgroundColor = dutyColor.withValues(alpha: 0.22);
    } else if (isCurrentMonth) {
      backgroundColor = onDuty ? dutyColor.withValues(alpha: 0.68) : dutyColor.withValues(alpha: 0.32);
    } else {
      if (onDuty) {
        backgroundColor = dutyColor.withValues(alpha: 0.12);
      } else if (hasEntry) {
        backgroundColor = colors.secondaryContainer.withValues(alpha: 0.18);
      } else {
        backgroundColor = colors.surfaceContainerHighest.withValues(alpha: 0.18);
      }
    }

    Color borderColor = Colors.transparent;
    double borderWidth = 1.2;
    if (isToday) {
      borderColor = colors.primary;
      borderWidth = 2.2;
    } else if (widget.isEditing && onDuty) {
      borderColor = colors.primary.withValues(alpha: 0.7);
      borderWidth = 2.0;
    }

    Color textColor;
    if (widget.isEditing && onDuty) {
      textColor = colors.primary;
    } else if (isCurrentMonth && onDuty) {
      textColor = _contrastingTextColor(backgroundColor, colors);
    } else if (isCurrentMonth) {
      textColor = colors.onSurface.withValues(alpha: 0.8);
    } else {
      textColor = colors.onSurfaceVariant.withValues(alpha: 0.55);
    }

    final overlayTextColor = _contrastingTextColor(dutyColor, colors);
    final overlayHeight = cellHeight * 0.3;
    final isEditableDay = widget.isEditing && onDuty;

    return SizedBox(
      width: cellWidth,
      height: cellHeight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _handleDayTap(dateOnly, isEditableDay);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (plannedOff)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: overlayHeight,
                      child: Container(
                        color: dutyColor,
                        alignment: Alignment.center,
                        child: Text(
                          '${dateOnly.day}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: overlayTextColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!plannedOff)
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${dateOnly.day}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (widget.isEditing && onDuty)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              hasScheduledService ? Icons.check_circle : Icons.add_circle_outline,
                              size: 18,
                              color: hasScheduledService
                                  ? colors.primary
                                  : colors.primary.withValues(alpha: 0.7),
                            ),
                          )
                        else if (hasScheduledService && !plannedOff)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: overlayTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDayTap(DateTime day, bool isEditableDay) async {
    if (widget.isEditing) {
      if (!isEditableDay || widget.onAssignScheduledService == null) {
        return;
      }
      await widget.onAssignScheduledService!(day);
      return;
    }
    widget.onDaySelected?.call(day);
  }

  Color _contrastingTextColor(Color background, ColorScheme scheme) {
    final luminance = background.computeLuminance();
    if (luminance < 0.35) {
      return Colors.white;
    }
    if (luminance < 0.65) {
      return scheme.onPrimaryContainer;
    }
    return scheme.onSurface;
  }

  bool _replacesScheduleOnCalendar(CalendarEntry entry) {
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

  List<DateTime> _daysInVisibleMonth() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final leading = (first.weekday + 6) % 7;
    final trailing = 6 - ((last.weekday + 6) % 7);
    final start = first.subtract(Duration(days: leading));
    final end = last.add(Duration(days: trailing));

    final days = <DateTime>[];
    for (DateTime day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
      days.add(day);
    }
    return days;
  }

  List<String> _polishWeekdayLabels() {
    return const <String>['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
  }

  String _polishMonthLabel(DateTime month) {
    const months = <String>[
      'styczeń',
      'luty',
      'marzec',
      'kwiecień',
      'maj',
      'czerwiec',
      'lipiec',
      'sierpień',
      'wrzesień',
      'październik',
      'listopad',
      'grudzień',
    ];
    final index = month.month - 1;
    final monthName = (index >= 0 && index < months.length) ? months[index] : '';
    return '$monthName ${month.year}';
  }

  void _goToPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      widget.onMonthChanged?.call(_visibleMonth);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      widget.onMonthChanged?.call(_visibleMonth);
    });
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.isEditing,
    required this.onEditToggle,
  });

  final String title;
  final bool isEditing;
  final VoidCallback? onEditToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton.filledTonal(
          onPressed: onEditToggle,
          tooltip: isEditing ? 'Zakończ edycję harmonogramu' : 'Włącz edycję harmonogramu',
          icon: Icon(isEditing ? Icons.edit_off_outlined : Icons.edit_calendar_outlined),
        ),
      ],
    );
  }
}

class _EditingBanner extends StatelessWidget {
  const _EditingBanner({required this.onExit});

  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final bg = palette.surfaceTint.withValues(alpha: 0.08);
    final border = palette.primary.withValues(alpha: 0.24);

    return Container(
      key: const ValueKey('editing-banner'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_calendar,
              color: ThemeData.estimateBrightnessForColor(palette.primary) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Tryb edycji: dotknij dzień swojej zmiany, aby dodać 24h służby do harmonogramu.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (onExit != null)
            FilledButton.tonal(
              onPressed: onExit,
              child: const Text('Zakończ'),
            ),
        ],
      ),
    );
  }
}
