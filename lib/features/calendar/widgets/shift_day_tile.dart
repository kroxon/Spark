import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/on_duty_indicator.dart';

/// Represents a single day cell within the monthly calendar grid.
class ShiftDayTile extends StatelessWidget {
  const ShiftDayTile({
    super.key,
    required this.day,
    required this.visibleMonth,
    required this.cellWidth,
    required this.cellHeight,
    required this.isEditing,
    required this.shiftCycleCalculator,
    required this.shiftHistory,
    required this.shiftColorPalette,
    required this.overtimeIndicatorThresholdHours,
    this.entry,
    this.onDaySelected,
    this.onToggleScheduledService,
  });

  final DateTime day;
  final DateTime visibleMonth;
  final double cellWidth;
  final double cellHeight;
  final bool isEditing;
  final ShiftCycleCalculator shiftCycleCalculator;
  final List<ShiftAssignment> shiftHistory;
  final ShiftColorPalette shiftColorPalette;
  final double overtimeIndicatorThresholdHours;
  final CalendarEntry? entry;
  final ValueChanged<DateTime>? onDaySelected;
  final Future<void> Function(DateTime day, bool assign)?
  onToggleScheduledService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateOnly = DateUtils.dateOnly(day);
    final isCurrentMonth =
        dateOnly.year == visibleMonth.year &&
        dateOnly.month == visibleMonth.month;
    final isToday = DateUtils.isSameDay(DateTime.now(), dateOnly);
    final onDuty = shiftCycleCalculator.isScheduledDayForUser(
      dateOnly,
      shiftHistory,
    );
    final shiftOnDuty = shiftCycleCalculator.shiftOn(dateOnly);
    final hasEntry = entry != null;
    final hasScheduledService = (entry?.scheduledHours ?? 0) > 0;
    final plannedOff = onDuty && _isDayReplacingSchedule(entry);
    final dutyColor = shiftColorPalette.colorForShift(shiftOnDuty);
    final hasPureScheduledService =
        hasScheduledService && (entry?.events.isEmpty ?? true);
    final meetsOvertimeThreshold =
        (entry?.overtimeHours ?? 0) >= overtimeIndicatorThresholdHours;
    final showOnDutyIndicator =
        !isEditing &&
        !plannedOff &&
        (hasPureScheduledService || meetsOvertimeThreshold);

    Color backgroundColor;
    if (isEditing && onDuty) {
      backgroundColor = dutyColor.withValues(alpha: 0.22);
    } else if (isCurrentMonth) {
      backgroundColor = onDuty
          ? dutyColor.withValues(alpha: 0.68)
          : dutyColor.withValues(alpha: 0.32);
    } else {
      if (onDuty) {
        backgroundColor = dutyColor.withValues(alpha: 0.12);
      } else if (hasEntry) {
        backgroundColor = colors.secondaryContainer.withValues(alpha: 0.18);
      } else {
        backgroundColor = colors.surfaceContainerHighest.withValues(
          alpha: 0.18,
        );
      }
    }

    Color borderColor = Colors.transparent;
    double borderWidth = 1.2;
    if (isToday) {
      borderColor = colors.primary;
      borderWidth = 2.2;
    } else if (isEditing && onDuty) {
      borderColor = colors.primary.withValues(alpha: 0.7);
      borderWidth = 2.0;
    }

    Color textColor;
    if (isEditing && onDuty) {
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
    final isEditableDay = isEditing && onDuty;

    return SizedBox(
      width: cellWidth,
      height: cellHeight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await _handleTap(dateOnly, isEditableDay, hasScheduledService);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
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
                        if (showOnDutyIndicator)
                          const Expanded(
                            child: Center(child: OnDutyIndicator()),
                          )
                        else
                          const Spacer(),
                        if (isEditing && onDuty)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(
                              hasScheduledService
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              size: 18,
                              color: hasScheduledService
                                  ? colors.error.withValues(alpha: 0.85)
                                  : colors.primary.withValues(alpha: 0.8),
                            ),
                          )
                        else if (!showOnDutyIndicator &&
                            hasScheduledService &&
                            !plannedOff)
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

  Future<void> _handleTap(
    DateTime day,
    bool isEditableDay,
    bool hasScheduledService,
  ) async {
    if (isEditing) {
      if (!isEditableDay || onToggleScheduledService == null) {
        return;
      }
      final shouldAssign = !hasScheduledService;
      await onToggleScheduledService!(day, shouldAssign);
      return;
    }
    onDaySelected?.call(day);
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

  bool _isDayReplacingSchedule(CalendarEntry? entry) {
    if (entry == null || entry.events.isEmpty) {
      return false;
    }
    for (final event in entry.events) {
      if (_eventBlocksSchedule(event)) {
        return true;
      }
    }
    return false;
  }

  bool _eventBlocksSchedule(DayEvent event) {
    switch (event.type) {
      case EventType.vacationRegular:
      case EventType.vacationAdditional:
      case EventType.sickLeave80:
      case EventType.sickLeave100:
      case EventType.otherAbsence:
      case EventType.delegation:
      case EventType.bloodDonation:
        return true;
      case EventType.customAbsence:
        return event.hours > 0;
      default:
        return false;
    }
  }
}
