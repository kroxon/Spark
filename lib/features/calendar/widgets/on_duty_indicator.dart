import 'package:flutter/material.dart';

class OnDutyIndicator extends StatelessWidget {
  const OnDutyIndicator({
    super.key,
    this.padding = const EdgeInsets.all(4),
    this.glowBlurRadius = 8,
    this.glowSpreadRadius = 2,
    this.iconSize = 9,
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
    final baseCircle = Colors.transparent;
    final baseGlow = Colors.yellow.shade400.withOpacity(0.75);
    final baseIcon = Colors.white;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor ?? baseCircle,
        boxShadow: [
          BoxShadow(
            color: glowColor ?? baseGlow,
            blurRadius: (glowBlurRadius - 2) * 0.75,
            spreadRadius: glowSpreadRadius,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(iconSize * 1.25 + 6, iconSize * 1.25 + 6),
            painter: _CirclePainter(),
          ),
          Icon(Icons.check, size: iconSize * 1.25, color: iconColor ?? baseIcon),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, 2 * 3.141592653589793 * 0.9, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
