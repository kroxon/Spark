import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/shift_day_tile.dart';

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
    this.onToggleScheduledService,
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
  final Future<void> Function(DateTime day, bool assign)?
  onToggleScheduledService;

  @override
  State<ShiftMonthCalendar> createState() => _ShiftMonthCalendarState();
}

class _ShiftMonthCalendarState extends State<ShiftMonthCalendar> {
  late DateTime _visibleMonth;
  late List<ShiftAssignment> _sortedShiftHistory;
  late Map<DateTime, CalendarEntry> _entriesByDate;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialMonth.year,
      widget.initialMonth.month,
    );
    _buildShiftHistory();
    _buildEntries();
  }

  @override
  void didUpdateWidget(covariant ShiftMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth.year != oldWidget.initialMonth.year ||
        widget.initialMonth.month != oldWidget.initialMonth.month) {
      _visibleMonth = DateTime(
        widget.initialMonth.year,
        widget.initialMonth.month,
      );
    }

    if (!identical(widget.userProfile, oldWidget.userProfile) ||
        widget.userProfile.shiftHistory.length !=
            oldWidget.userProfile.shiftHistory.length) {
      _buildShiftHistory();
    }

    if (!identical(widget.entries, oldWidget.entries) ||
        !listEquals(widget.entries, oldWidget.entries)) {
      _buildEntries();
    }
  }

  void _buildShiftHistory() {
    _sortedShiftHistory = List<ShiftAssignment>.from(
      widget.userProfile.shiftHistory,
    )..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  void _buildEntries() {
    _entriesByDate = <DateTime, CalendarEntry>{};
    for (final entry in widget.entries) {
      final day = DateUtils.dateOnly(entry.date);
      final existing = _entriesByDate[day];
      if (existing == null || entry.date.isAfter(existing.date)) {
        _entriesByDate[day] = entry;
      }
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
              ? _EditingBanner(onExit: widget.onEditModeToggle)
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
                      child: Text(day, style: theme.textTheme.labelSmall),
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
              final cellHeight = cellWidth * 1.4;
              final tableHeight = cellHeight * rowCount;
              final columnWidths = <int, TableColumnWidth>{
                for (var i = 0; i < 7; i++) i: FixedColumnWidth(cellWidth),
              };
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: tableHeight,
                  child: Table(
                    columnWidths: columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: _buildRows(days, cellWidth, cellHeight),
                  ),
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
    );

    if (!widget.showMonthNavigation) {
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: header);
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

  List<TableRow> _buildRows(
    List<DateTime> days,
    double cellWidth,
    double cellHeight,
  ) {
    final rows = <TableRow>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = days.sublist(i, i + 7);
      rows.add(
        TableRow(
          children: week.map((day) {
            final dateOnly = DateUtils.dateOnly(day);
            return ShiftDayTile(
              day: dateOnly,
              visibleMonth: _visibleMonth,
              cellWidth: cellWidth,
              cellHeight: cellHeight,
              isEditing: widget.isEditing,
              shiftCycleCalculator: widget.shiftCycleCalculator,
              shiftHistory: _sortedShiftHistory,
              shiftColorPalette: widget.userProfile.shiftColorPalette,
              overtimeIndicatorThresholdHours:
                  widget.userProfile.overtimeIndicatorThresholdHours,
              onDutyIndicatorColor: widget.userProfile.onDutyIndicatorColor,
              entry: _entriesByDate[dateOnly],
              onDaySelected: widget.onDaySelected,
              onToggleScheduledService: widget.onToggleScheduledService,
            );
          }).toList(),
        ),
      );
    }
    return rows;
  }

  List<DateTime> _daysInVisibleMonth() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    final leading = (first.weekday + 6) % 7;
    final trailing = 6 - ((last.weekday + 6) % 7);
    final start = first.subtract(Duration(days: leading));
    final end = last.add(Duration(days: trailing));

    final days = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDate)) {
      days.add(current);
      final nextDay = current.day + 1;
      final daysInCurrentMonth = DateTime(current.year, current.month + 1, 0).day;
      if (nextDay > daysInCurrentMonth) {
        if (current.month == 12) {
          current = DateTime(current.year + 1, 1, 1);
        } else {
          current = DateTime(current.year, current.month + 1, 1);
        }
      } else {
        current = DateTime(current.year, current.month, nextDay);
      }
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
    final monthName = (index >= 0 && index < months.length)
        ? months[index]
        : '';
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
  });

  final String title;

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
          Expanded(
            child: Text(
              'Tryb edycji: dotknij dzień swojej zmiany, aby dodać 24h służby do harmonogramu.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (onExit != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: FilledButton.tonal(
                onPressed: onExit,
                child: const Text('Zakończ'),
              ),
            ),
        ],
      ),
    );
  }
}
