import 'dart:math' as math;
import 'package:flutter/material.dart';

class RankPainter extends CustomPainter {
  final int value;

  RankPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A237E) // Dark blue background (PSP style)
      ..style = PaintingStyle.fill;

    // Draw background (shoulder strap shape - slightly rounded rectangle)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);

    final insigniaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFC107),
          Color(0xFFFFE082),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    switch (value) {
      case 2:
        break;
      case 4:
        _drawStripes(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 8:
        _drawStripes(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 16:
        _drawStripes(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 32:
        _drawStripes(canvas, center, w, h, 4, insigniaPaint);
        break;
      case 64:
        _drawChevrons(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 128:
        _drawChevrons(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 256:
        _drawAspirantInsignia(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 512:
        _drawStars(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 1024:
        _drawStars(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 2048:
        _drawStars(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 4096:
        _drawCaptainInsignia(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 8192:
        _drawCaptainInsignia(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 16384:
        _drawCaptainInsignia(canvas, center, w, h, 4, insigniaPaint);
        break;
      case 32768:
        _drawBrigadierInsignia(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 65536:
        _drawBrigadierInsignia(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 131072:
        _drawBrigadierInsignia(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 262144:
        _drawGeneralZigzag(canvas, size, insigniaPaint);
        _drawStars(canvas, Offset(center.dx, center.dy - h * 0.15), w, h, 1, insigniaPaint);
        break;
      case 524288:
        _drawGeneralZigzag(canvas, size, insigniaPaint);
        _drawStars(canvas, Offset(center.dx, center.dy - h * 0.15), w, h, 2, insigniaPaint);
        break;
      default:
        if (value > 0) {
          final textSpan = TextSpan(
            text: '$value',
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
        }
    }
  }

  void _drawStripes(Canvas canvas, Offset center, double w, double h, int count, Paint paint) {
    final stripeHeight = h * 0.08;
    final stripeWidth = w * 0.6;
    final gap = h * 0.05;
    final totalHeight = count * stripeHeight + (count - 1) * gap;
    double startY = center.dy - totalHeight / 2;
    for (int i = 0; i < count; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, startY + stripeHeight / 2),
          width: stripeWidth,
          height: stripeHeight,
        ),
        paint,
      );
      startY += stripeHeight + gap;
    }
  }

  void _drawChevrons(Canvas canvas, Offset center, double w, double h, int count, Paint paint) {
    final chevronHeight = h * 0.15;
    final chevronWidth = w * 0.6;
    final gap = h * 0.08;
    final totalHeight = count * chevronHeight + (count - 1) * gap;
    double startY = center.dy - totalHeight / 2;
    final strokeW = w * 0.1;
    final strokePaint = Paint()
      ..shader = paint.shader
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;
    for (int i = 0; i < count; i++) {
      final path = Path();
      path.moveTo(center.dx - chevronWidth / 2, startY);
      path.lineTo(center.dx, startY + chevronHeight);
      path.lineTo(center.dx + chevronWidth / 2, startY);
      canvas.drawPath(path, strokePaint);
      startY += chevronHeight + gap;
    }
  }

  void _drawStars(Canvas canvas, Offset center, double w, double h, int count, Paint paint) {
    final size = w * 0.18;
    final gap = size * 0.25;
    final totalWidth = count * size + (count - 1) * gap;
    double startX = center.dx - totalWidth / 2 + size / 2;
    for (int i = 0; i < count; i++) {
      _drawStarShape(canvas, Offset(startX, center.dy), size, paint);
      startX += size + gap;
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double diameter, Paint paint) {
    final radius = diameter / 2;
    final innerRadius = radius * 0.4;
    final path = Path();
    double angle = -math.pi / 2;
    final step = math.pi / 5;
    path.moveTo(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle)
    );
    for (int i = 1; i < 10; i++) {
      angle += step;
      double r = (i % 2 == 1) ? innerRadius : radius;
      path.lineTo(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle)
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawGeneralZigzag(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final left = w * 0.08;
    final right = w * 0.92;
    final baseY = h * 0.88;
    final peakY = h * 0.68;
    final bandWidth = h * 0.13;
    final chevronCount = 3;
    final chevronWidth = (right - left) / chevronCount;
    for (int i = 0; i < chevronCount; i++) {
      final x0 = left + i * chevronWidth;
      final x1 = x0 + chevronWidth / 2;
      final x2 = x0 + chevronWidth;
      final band = Path();
      band.moveTo(x0, baseY);
      band.lineTo(x1, peakY);
      band.lineTo(x2, baseY);
      band.lineTo(x2, baseY + bandWidth);
      band.lineTo(x1, peakY + bandWidth);
      band.lineTo(x0, baseY + bandWidth);
      band.close();
      final fillPaint = Paint()
        ..shader = paint.shader
        ..style = PaintingStyle.fill;
      canvas.drawPath(band, fillPaint);
      final triCount = 4;
      for (int t = 0; t < triCount; t++) {
        final frac = t / triCount;
        final tx0 = x0 + (x1 - x0) * frac + bandWidth * 0.15;
        final tx1 = x0 + (x1 - x0) * (frac + 1.0 / triCount) - bandWidth * 0.15;
        final ty0 = baseY + bandWidth * 0.18;
        final ty1 = peakY + bandWidth * 0.18;
        final tri = Path();
        tri.moveTo(tx0, ty0);
        tri.lineTo(tx1, ty0);
        tri.lineTo((tx0 + tx1) / 2, ty1);
        tri.close();
        final triPaint = Paint()
          ..color = Colors.black.withOpacity(0.18)
          ..style = PaintingStyle.fill;
        canvas.drawPath(tri, triPaint);
      }
    }
    final interlacePaint = Paint()
      ..shader = paint.shader
      ..color = paint.color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < chevronCount; i++) {
      final x0 = left + i * chevronWidth;
      final x1 = x0 + chevronWidth / 2;
      final x2 = x0 + chevronWidth;
      final line = Path();
      line.moveTo(x0, baseY + bandWidth * 0.5);
      line.lineTo(x1, peakY + bandWidth * 0.5);
      line.lineTo(x2, baseY + bandWidth * 0.5);
      canvas.drawPath(line, interlacePaint);
      if (i < chevronCount - 1) {
        final nextX0 = left + (i + 1) * chevronWidth;
        final cross = Path();
        cross.moveTo(x1, peakY + bandWidth * 0.5);
        cross.lineTo(nextX0, baseY + bandWidth * 0.5);
        canvas.drawPath(cross, interlacePaint);
      }
    }
  }

  void _drawAspirantInsignia(Canvas canvas, Offset center, double w, double h, int starCount, Paint paint) {
    final vHeight = h * 0.3;
    final vWidth = w * 0.7;
    final strokeW = w * 0.08;
    final path = Path();
    path.moveTo(center.dx - vWidth / 2, center.dy - vHeight / 2);
    path.lineTo(center.dx, center.dy + vHeight / 2);
    path.lineTo(center.dx + vWidth / 2, center.dy - vHeight / 2);
    final strokePaint = Paint()
      ..shader = paint.shader
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, strokePaint);
    final starCenterY = center.dy - vHeight * 0.35;
    _drawStars(canvas, Offset(center.dx, starCenterY), w, h, starCount, paint);
  }

  void _drawCaptainInsignia(Canvas canvas, Offset center, double w, double h, int starCount, Paint paint) {
    final stripeHeight = h * 0.08;
    final stripeWidth = w * 0.6;
    final barCenterY = center.dy + h * 0.25;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, barCenterY),
        width: stripeWidth,
        height: stripeHeight,
      ),
      paint,
    );
    final starsCenterY = center.dy - h * 0.1;
    _drawStars(canvas, Offset(center.dx, starsCenterY), w, h, starCount, paint);
  }

  void _drawBrigadierInsignia(Canvas canvas, Offset center, double w, double h, int starCount, Paint paint) {
    final stripeHeight = h * 0.08;
    final stripeWidth = w * 0.6;
    final gap = h * 0.04;
    double currentY = center.dy + h * 0.2;
    for (int i = 0; i < 2; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, currentY),
          width: stripeWidth,
          height: stripeHeight,
        ),
        paint,
      );
      currentY += stripeHeight + gap;
    }
    final starsCenterY = center.dy - h * 0.15;
    _drawStars(canvas, Offset(center.dx, starsCenterY), w, h, starCount, paint);
  }

  @override
  bool shouldRepaint(covariant RankPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
