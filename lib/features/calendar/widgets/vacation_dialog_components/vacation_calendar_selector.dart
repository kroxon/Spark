import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';

class VacationCalendarSelector extends StatefulWidget {
  const VacationCalendarSelector({
    super.key,
    required this.userProfile,
    required this.startDate,
    required this.endDate,
    required this.onRangeSelected,
    required this.potentialConsumedHours,
  });

  final UserProfile userProfile;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?, DateTime) onRangeSelected;
  final double potentialConsumedHours;

  @override
  State<VacationCalendarSelector> createState() => _VacationCalendarSelectorState();
}

class _VacationCalendarSelectorState extends State<VacationCalendarSelector> {
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
  void didUpdateWidget(VacationCalendarSelector oldWidget) {
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
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isDefault: true);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isToday: true);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isSelected: true);
                },
                rangeStartBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isRangeStart: true);
                },
                rangeEndBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isRangeEnd: true);
                },
                withinRangeBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, focusedDay, isWithinRange: true);
                },
              ),
            ),
          ),
        ),
        if (_selectedStart != null && _selectedEnd != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wybrany okres: ${_formatDate(_selectedStart!)} - ${_formatDate(_selectedEnd!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Potencjalnie wykorzystane godziny: ${widget.potentialConsumedHours.toStringAsFixed(1)}h',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    bool isDefault = false,
    bool isToday = false,
    bool isSelected = false,
    bool isRangeStart = false,
    bool isRangeEnd = false,
    bool isWithinRange = false,
  }) {
    final theme = Theme.of(context);
    final shiftCalculator = ShiftCycleCalculator();
    final shiftId = shiftCalculator.shiftOn(day);
    final shiftColor = widget.userProfile.shiftColorPalette.colorForShift(shiftId);

    // Check if this day is scheduled for the user
    final isScheduled = shiftCalculator.isScheduledDayForUser(
      day,
      widget.userProfile.shiftHistory,
    );

    // Base background color based on shift
    Color backgroundColor = shiftColor.withValues(alpha: 0.3);

    // Override for special states
    if (isToday) {
      backgroundColor = theme.colorScheme.primaryContainer;
    } else if (isSelected || isRangeStart || isRangeEnd) {
      backgroundColor = theme.colorScheme.primary;
    } else if (isWithinRange) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
    }

    // Text color
    Color textColor = theme.colorScheme.onSurface;
    if (isSelected || isRangeStart || isRangeEnd) {
      textColor = theme.colorScheme.onPrimary;
    } else if (!isScheduled) {
      textColor = textColor.withValues(alpha: 0.4); // Dim text for non-scheduled days
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday && !isSelected && !isRangeStart && !isRangeEnd && !isWithinRange
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}