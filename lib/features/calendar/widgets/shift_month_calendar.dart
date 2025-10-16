import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/models/user_profile.dart';
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
  });

  final DateTime initialMonth;
  final UserProfile userProfile;
  final List<CalendarEntry> entries;
  final ShiftCycleCalculator shiftCycleCalculator;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged;
  final bool showMonthNavigation;

  @override
  State<ShiftMonthCalendar> createState() => _ShiftMonthCalendarState();
}

class _ShiftMonthCalendarState extends State<ShiftMonthCalendar> {
  static const double _tileHeight = 96;
  late DateTime _visibleMonth;
  late List<ShiftAssignment> _sortedShiftHistory;
  late Map<DateTime, List<CalendarEntry>> _entriesByDate;
  DateTime? _selectedDay;

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
        if (widget.showMonthNavigation)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPreviousMonth,
              ),
              Expanded(
                child: Text(
                  headerLabel,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goToNextMonth,
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              headerLabel,
              style: theme.textTheme.titleMedium,
            ),
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
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / 7;
            final columnWidths = <int, TableColumnWidth>{
              for (var i = 0; i < 7; i++) i: FixedColumnWidth(cellWidth),
            };
            return Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: _buildRows(days, theme, cellWidth),
            );
          },
        ),
      ],
    );
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

  List<TableRow> _buildRows(List<DateTime> days, ThemeData theme, double cellWidth) {
    final rows = <TableRow>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = days.sublist(i, i + 7);
      rows.add(
        TableRow(
          children: week.map((day) => _buildCell(day, theme, cellWidth)).toList(),
        ),
      );
    }
    return rows;
  }

  Widget _buildCell(DateTime day, ThemeData theme, double cellWidth) {
    final colors = theme.colorScheme;
    final dateOnly = DateUtils.dateOnly(day);
    final isCurrentMonth = dateOnly.year == _visibleMonth.year && dateOnly.month == _visibleMonth.month;
    final isSelected = _selectedDay != null && DateUtils.isSameDay(_selectedDay, dateOnly);
    final isToday = DateUtils.isSameDay(DateTime.now(), dateOnly);
    final onDuty = widget.shiftCycleCalculator.isScheduledDayForUser(dateOnly, _sortedShiftHistory);
    final shiftOnDuty = widget.shiftCycleCalculator.shiftOn(dateOnly);
    final entries = _entriesByDate[dateOnly] ?? const <CalendarEntry>[];
    final hasEntry = entries.isNotEmpty;
    final plannedOff = onDuty && entries.any(
      (entry) => entry.entryType == EntryType.dayOff ||
          entry.entryType == EntryType.vacationStandard ||
          entry.entryType == EntryType.vacationAdditional,
    );
    final dutyColor = widget.userProfile.shiftColorPalette.colorForShift(shiftOnDuty);

    Color backgroundColor;
    if (isCurrentMonth) {
      if (onDuty) {
        backgroundColor = dutyColor.withValues(alpha: 0.68);
      } else {
        backgroundColor = dutyColor.withValues(alpha: 0.32);
      }
    } else {
      if (onDuty) {
        backgroundColor = dutyColor.withValues(alpha: 0.12);
      } else if (hasEntry) {
        backgroundColor = colors.secondaryContainer.withValues(alpha: 0.18);
      } else {
        backgroundColor = colors.surfaceContainerHighest.withValues(alpha: 0.18);
      }
    }

    final borderColor = isToday ? colors.primary : Colors.transparent;
    final borderWidth = isToday ? 2.2 : 1.2;
    Color textColor;
    if (isCurrentMonth && onDuty) {
      textColor = _contrastingTextColor(backgroundColor, colors);
    } else if (isCurrentMonth) {
      textColor = colors.onSurface.withValues(alpha: 0.8);
    } else {
      textColor = colors.onSurfaceVariant.withValues(alpha: 0.55);
    }
    final shadowColor = isSelected ? colors.primary.withValues(alpha: 0.2) : Colors.transparent;
    final overlayTextColor = _contrastingTextColor(dutyColor, colors);
    final overlayHeight = _tileHeight * 0.3;

    return SizedBox(
      width: cellWidth,
      height: _tileHeight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleDayTap(dateOnly),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadowColor == Colors.transparent
                  ? null
                  : [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            padding: EdgeInsets.zero,
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
                      mainAxisAlignment: MainAxisAlignment.start,
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

  void _handleDayTap(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
    widget.onDaySelected?.call(day);
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
