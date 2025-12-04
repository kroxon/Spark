
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

    // 1. Draw Track (Background Ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw Progress Arc with Gradient
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      // Create a gradient that fades from transparent to full color
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        tileMode: TileMode.repeated,
        colors: [
          color.withOpacity(0.0), // Start transparent
          color.withOpacity(0.5),
          color, // End solid
        ],
        stops: const [0.0, 0.7, 1.0],
      );

      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // We draw the arc. Note: SweepGradient applies to the whole rect, 
      // so we need to be careful with rotation if we want it to follow perfectly.
      // But for a simple progress, masking or rotating the canvas is often easier.
      // Here, since we want the gradient to "follow" the sweep, we can just use the shader on the arc.
      
      // However, standard SweepGradient is angular based on center. 
      // To make the gradient "tail" follow the progress, we need to rotate the gradient 
      // or just map the colors to the current sweep angle.
      
      // Let's try a simpler approach for the "tail" effect:
      // Map the gradient to the full circle but only draw the arc.
      // The colors list needs to be dynamic based on progress if we want the "head" to always be solid color.
      // Actually, SweepGradient naturally does this if we set endAngle correctly in the shader? 
      // No, createShader(rect) maps to the rect.
      
      // Better approach for "Comet" look:
      // Rotate the canvas so the gradient aligns with the arc?
      // Or just use the SweepGradient as is, but we need to make sure the "solid" part is at the current progress tip.
      
      // Let's stick to a nice gradient from start to end of the arc.
      
      canvas.save();
      canvas.rotate(-math.pi / 2); // Rotate -90 deg so 0 is at top
      canvas.translate(-center.dx, -center.dy); // Adjust for rotation pivot if needed? 
      // Actually rotate around center:
      canvas.restore();
      
      // Let's just draw the arc with the shader.
      // The SweepGradient starts at 3 o'clock (0 radians) by default.
      // We want it to start at -pi/2 (12 o'clock).
      
      final gradientShader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        tileMode: TileMode.clamp,
        colors: [
          color.withOpacity(0.1),
          color,
        ],
      ).createShader(rect);
      
      progressPaint.shader = gradientShader;

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // 3. Draw Glow/Shadow at the tip (The "Head")
      final endAngle = startAngle + sweepAngle;
      final knobX = center.dx + radius * math.cos(endAngle);
      final knobY = center.dy + radius * math.sin(endAngle);
      final knobCenter = Offset(knobX, knobY);

      // Outer Glow for the knob
      final knobGlowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(knobCenter, strokeWidth / 1.5, knobGlowPaint);

      // Inner Knob (Solid Dot)
      final knobPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(knobCenter, strokeWidth / 3.5, knobPaint);
      
      // Ring around knob
      final knobRingPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(knobCenter, strokeWidth / 3.5, knobRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ModernProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.trackColor != trackColor;
  }
}
