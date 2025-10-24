import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';

class DayEventIconsRow extends StatelessWidget {
  const DayEventIconsRow({
    super.key,
    required this.events,
    this.iconColor,
    this.iconSize = 14,
    this.spacing = 4,
    this.maxIcons = 3,
  }) : assert(maxIcons >= 2, 'maxIcons must allow for overflow indicator.');

  final List<DayEvent> events;
  final Color? iconColor;
  final double iconSize;
  final double spacing;
  final int maxIcons;

  @override
  Widget build(BuildContext context) {
    final icons = _iconList();
    if (icons.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedColor = iconColor ??
            Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.85,
                );
        final hasOverflow = icons.length > maxIcons;
        final visibleCount = hasOverflow ? maxIcons - 1 : icons.length;
        final visible = icons.take(visibleCount).toList(growable: false);
        final overflow = hasOverflow ? icons.length - visibleCount : 0;

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
    final spacingTotal =
      visible.isEmpty ? 0.0 : spacing * (visible.length - 1);
    final overflowPadding =
      overflow > 0 && visible.isNotEmpty ? spacing : 0.0;
        final overflowWidth = overflow > 0
            ? _measureOverflowTextWidth(context, overflow)
            : 0;

        var targetSize = iconSize;
        if (availableWidth.isFinite) {
          final remaining =
              availableWidth - spacingTotal - overflowWidth - overflowPadding;
          if (visible.isNotEmpty) {
            final maxIconSize = remaining / visible.length;
            targetSize = maxIconSize.clamp(8.0, iconSize).toDouble();
          } else if (overflow > 0) {
            targetSize = iconSize;
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : spacing),
                child: Icon(
                  visible[i],
                  size: targetSize,
                  color: resolvedColor,
                ),
              ),
            if (overflow > 0)
              Padding(
                padding: EdgeInsets.only(left: visible.isEmpty ? 0 : spacing),
                child: Text(
                  '+$overflow',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: resolvedColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _measureOverflowTextWidth(BuildContext context, int overflow) {
    final textStyle = Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final painter = TextPainter( 
      text: TextSpan(text: '+$overflow', style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  List<IconData> _iconList() {
    final seen = <EventType>{};
    final result = <IconData>[];
    for (final event in events) {
      if (seen.add(event.type)) {
        final icon = _iconFor(event.type);
        if (icon != null) {
          result.add(icon);
        }
      }
    }
    return result;
  }

  IconData? _iconFor(EventType type) {
    switch (type) {
      case EventType.overtimeWorked:
        return Icons.flash_on_outlined;
      case EventType.delegation:
        return Icons.flight_takeoff_outlined;
      case EventType.bloodDonation:
        return Icons.water_drop_outlined;
      case EventType.vacationRegular:
        return Icons.beach_access;
      case EventType.vacationAdditional:
        return Icons.park_outlined;
      case EventType.sickLeave80:
      case EventType.sickLeave100:
        return Icons.medical_services_outlined;
      case EventType.paidAbsence:
        return Icons.person_off_outlined;
      case EventType.overtimeTimeOff:
        return Icons.timelapse;
      case EventType.homeDuty:
        return Icons.home_outlined;
      case EventType.unpaidAbsence:
        return Icons.person_remove_outlined;
    }
  }
}
