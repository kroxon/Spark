import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class SickLeaveCalendarSelector extends StatefulWidget {
  const SickLeaveCalendarSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onRangeSelected,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?, DateTime) onRangeSelected;

  @override
  State<SickLeaveCalendarSelector> createState() => _SickLeaveCalendarSelectorState();
}

class _SickLeaveCalendarSelectorState extends State<SickLeaveCalendarSelector> {
  late DateTime _focusedDay;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedStart = widget.startDate;
    _selectedEnd = widget.endDate;
  }

  @override
  void didUpdateWidget(SickLeaveCalendarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate || widget.endDate != oldWidget.endDate) {
      setState(() {
        _selectedStart = widget.startDate;
        _selectedEnd = widget.endDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Okres zwolnienia',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedStart, day) || isSameDay(_selectedEnd, day),
              rangeStartDay: _selectedStart,
              rangeEndDay: _selectedEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _selectedStart = start;
                  _selectedEnd = end;
                  _focusedDay = focusedDay;
                });
                widget.onRangeSelected(start, end, focusedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                weekendTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ?? const TextStyle(),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                headerPadding: const EdgeInsets.only(bottom: 8),
              ),
            ),
          ),
        ),
        if (_selectedStart != null && _selectedEnd != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Wybrany okres: ${_formatDate(_selectedStart!)} - ${_formatDate(_selectedEnd!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}