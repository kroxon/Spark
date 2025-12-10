
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ModernProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  ModernProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw Track (Background Ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw Progress Arc with Gradient
    if (progress > 0) {
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      // Fix: Rotate gradient to start at 12 o'clock (-pi/2) to avoid 3 o'clock artifact
      final gradient = SweepGradient(
        startAngle: 0.0,
        endAngle: sweepAngle,
        tileMode: TileMode.clamp,
        colors: [
          color.withOpacity(0.0),
          color,
        ],
        transform: GradientRotation(startAngle), 
      );

      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // 3. Glow/Bloom at the tip (The "Head")
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      final tipCenter = Offset(tipX, tipY);

      // Outer Glow
      final glowPaint = Paint()
        ..color = color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(tipCenter, strokeWidth * 0.6, glowPaint);

      // Inner Dot (White or bright accent)
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(tipCenter, strokeWidth * 0.25, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ModernProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.trackColor != trackColor;
  }
}
