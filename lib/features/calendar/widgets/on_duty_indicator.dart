import 'package:flutter/material.dart';

class OnDutyIndicator extends StatelessWidget {
  const OnDutyIndicator({
    super.key,
    this.padding = const EdgeInsets.all(5),
    this.glowBlurRadius = 10,
    this.glowSpreadRadius = 2,
    this.iconSize = 12,
    this.circleColor,
    this.glowColor,
    this.iconColor,
  });

  final EdgeInsets padding;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double iconSize;
  final Color? circleColor;
  final Color? glowColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final baseCircle = Colors.yellow.shade600.withOpacity(0.85);
    final baseGlow = Colors.yellow.shade400.withOpacity(0.6);
    final baseIcon = Colors.green.shade700;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor ?? baseCircle,
        boxShadow: [
          BoxShadow(
            color: glowColor ?? baseGlow,
            blurRadius: glowBlurRadius,
            spreadRadius: glowSpreadRadius,
          ),
        ],
      ),
      child: Icon(Icons.check, size: iconSize, color: iconColor ?? baseIcon),
    );
  }
}
