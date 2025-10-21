import 'package:flutter/material.dart';

class DayDetailHeader extends StatelessWidget {
  const DayDetailHeader({
    super.key,
    required this.dayLabel,
    required this.shiftLabel,
    required this.shiftColor,
  });

  final String dayLabel;
  final String shiftLabel;
  final Color shiftColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        ThemeData.estimateBrightnessForColor(shiftColor) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dayLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: shiftColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              shiftLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
