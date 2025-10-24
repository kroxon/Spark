import 'package:flutter/material.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/day_event_icons_row.dart';
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
      borderColor = colors.primary.withValues(alpha: 0.8);
      borderWidth = 2.2;
    } else if (isEditing && onDuty) {
      borderColor = colors.primary.withValues(alpha: 0.7);
      borderWidth = 2.0;
    }

    final brightness = theme.brightness;
    Color textColor;
    if (isEditing && onDuty) {
      textColor = brightness == Brightness.dark
          ? _contrastingTextColor(backgroundColor, colors)
          : colors.primary;
    } else if (brightness == Brightness.dark && isCurrentMonth) {
      textColor = _contrastingTextColor(backgroundColor, colors);
    } else if (isCurrentMonth && onDuty) {
      textColor = _contrastingTextColor(backgroundColor, colors);
    } else if (isCurrentMonth) {
      textColor = colors.onSurface.withValues(alpha: 0.8);
    } else {
      textColor = colors.onSurfaceVariant.withValues(alpha: 0.55);
    }

    final isEditableDay = isEditing && onDuty;
    final events = entry?.events ?? const <DayEvent>[];
    final shouldShowEventIcons = events.isNotEmpty;
  final double dayNumberFontSize =
    ((cellWidth * 0.3).clamp(12, 20) * 0.75).clamp(9, 15);
  final baseDayNumberStyle =
      (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w600,
    fontSize: dayNumberFontSize,
    height: 1.0,
  );
  final showScheduleIcon = hasScheduledService && !isEditing;
  final showScheduleGlyph = isEditableDay &&
    !shouldShowEventIcons &&
    !showOnDutyIndicator &&
    hasScheduledService &&
    !isEditing;
  final hasBottomContent =
      (shouldShowEventIcons && !isEditing) || showScheduleGlyph;
  final scheduleGlyphColor = colors.onSurfaceVariant.withValues(
    alpha: isCurrentMonth ? 0.75 : 0.5,
  );

  final dayNumberStyle = baseDayNumberStyle.copyWith(color: textColor);
  final scheduleIconColor = colors.onSurfaceVariant.withValues(alpha: 0.75);    return SizedBox(
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
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              '${dateOnly.day}',
                              style: dayNumberStyle,
                            ),
                            if (showScheduleIcon)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    size: dayNumberFontSize + 2,
                                    color: scheduleIconColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // const SizedBox(height: 4),
                        Expanded(
                          child: isEditableDay
                              ? Center(
                                  child: Icon(
                                    hasScheduledService
                                        ? Icons.remove_circle
                                        : Icons.add_circle,
                                    size: (cellWidth * 0.5).clamp(20, 40),
                                    color: hasScheduledService
                                        ? Colors.red.shade600
                                        : Colors.green.shade600,
                                  ),
                                )
                              : showOnDutyIndicator
                                  ? Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Center(
                                        child: OnDutyIndicator(
                                          iconSize: (cellWidth * 0.15).clamp(6, 12),
                                          glowColor: brightness == Brightness.dark
                                              ? Colors.yellow.shade400.withOpacity(0.4)
                                              : null,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                        ),
                        if (hasBottomContent) const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  if (hasBottomContent)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: (!isEditing && shouldShowEventIcons)
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: DayEventIconsRow(
                                        events: events,
                                        iconColor: colors.onSurfaceVariant
                                            .withValues(
                                          alpha:
                                              isCurrentMonth ? 0.85 : 0.6,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (isEditableDay)
                              const SizedBox.shrink()
                            else if (showScheduleGlyph)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: (!isEditing && shouldShowEventIcons) ? 6 : 0,
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  size: (cellWidth * 0.25).clamp(10, 16),
                                  color: scheduleGlyphColor,
                                ),
                              ),
                          ],
                        ),
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
