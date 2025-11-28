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

    // Insignia paint - GOLD
    final insigniaPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD700), // Gold
          Color(0xFFFFC107), // Amber
          Color(0xFFFFE082), // Light Gold
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Ensure stroke paint also uses gold shader or color
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFB300),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFB300),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    switch (value) {
      case 2: // Strażak - Puste
        // No insignia
        break;
      case 4: // Starszy strażak - 1 belka
        _drawStripes(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 8: // Sekcyjny - 2 belki
        _drawStripes(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 16: // Starszy sekcyjny - 3 belki
        _drawStripes(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 32: // Młodszy ogniomistrz - 4 belki
        _drawStripes(canvas, center, w, h, 4, insigniaPaint);
        break;
      case 64: // Ogniomistrz - 1 krokiew
        _drawChevrons(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 128: // Starszy ogniomistrz - 2 krokwie
        _drawChevrons(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 256: // Młodszy aspirant - V + 1 gwiazdka
        _drawAspirantInsignia(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 512: // Aspirant - 1 gwiazdka
        _drawStars(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 1024: // Starszy aspirant - 2 gwiazdki
        _drawStars(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 2048: // Aspirant sztabowy - 3 gwiazdki
        _drawStars(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 4096: // Młodszy kapitan - 1 gwiazdka
        _drawStars(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 8192: // Kapitan - 2 gwiazdki
        _drawStars(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 16384: // Starszy kapitan - 3 gwiazdki
        _drawStars(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 32768: // Młodszy brygadier - 2 belki pionowe + 1 gwiazdka
        _drawOfficerStripes(canvas, size, borderPaint);
        _drawStars(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 65536: // Brygadier - 2 belki pionowe + 2 gwiazdki
        _drawOfficerStripes(canvas, size, borderPaint);
        _drawStars(canvas, center, w, h, 2, insigniaPaint);
        break;
      case 131072: // Starszy brygadier - 2 belki pionowe + 3 gwiazdki
        _drawOfficerStripes(canvas, size, borderPaint);
        _drawStars(canvas, center, w, h, 3, insigniaPaint);
        break;
      case 262144: // Nadbrygadier - Wężyk + 1 gwiazdka
        _drawGeneralZigzag(canvas, size, borderPaint);
        _drawStars(canvas, center, w, h, 1, insigniaPaint);
        break;
      case 524288: // Generał brygadier - Wężyk + 2 gwiazdki
        _drawGeneralZigzag(canvas, size, borderPaint);
        _drawStars(canvas, center, w, h, 2, insigniaPaint);
        break;
      default:
        // Fallback for unknown or 0
        if (value > 0) {
           // Just draw text if way too high
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
    final chevronHeight = h * 0.12;
    final chevronWidth = w * 0.6;
    final gap = h * 0.05;
    final totalHeight = count * chevronHeight + (count - 1) * gap;
    
    double startY = center.dy - totalHeight / 2;

    // Use the gold shader paint for strokes too, but set style to stroke
    final strokePaint = Paint()
      ..shader = paint.shader
      ..color = paint.color // Fallback
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < count; i++) {
      final path = Path();
      path.moveTo(center.dx - chevronWidth / 2, startY + chevronHeight);
      path.lineTo(center.dx, startY);
      path.lineTo(center.dx + chevronWidth / 2, startY + chevronHeight);
      
      canvas.drawPath(path, strokePaint);
      startY += chevronHeight + gap;
    }
  }

  void _drawDiamonds(Canvas canvas, Offset center, double w, double h, int count, Paint paint) {
    final size = w * 0.15;
    final gap = size * 0.5;
    final totalHeight = count * size + (count - 1) * gap;
    
    double startY = center.dy - totalHeight / 2;

    for (int i = 0; i < count; i++) {
      final path = Path();
      final cy = startY + size / 2;
      path.moveTo(center.dx, cy - size / 2); // Top
      path.lineTo(center.dx + size / 2, cy); // Right
      path.lineTo(center.dx, cy + size / 2); // Bottom
      path.lineTo(center.dx - size / 2, cy); // Left
      path.close();
      
      canvas.drawPath(path, paint);
      startY += size + gap;
    }
  }

  void _drawStars(Canvas canvas, Offset center, double w, double h, int count, Paint paint) {
    final size = w * 0.2;
    final gap = size * 0.2;
    
    // Stars are usually arranged in a triangle or line depending on count.
    // 1: Center
    // 2: Vertical line
    // 3: Triangle (1 top, 2 bottom) or line?
    // In PSP:
    // 2 stars: vertical line
    // 3 stars: triangle (1 top, 2 bottom)
    
    List<Offset> positions = [];
    if (count == 1) {
      positions.add(center);
    } else if (count == 2) {
      positions.add(Offset(center.dx, center.dy - size / 2 - gap / 2));
      positions.add(Offset(center.dx, center.dy + size / 2 + gap / 2));
    } else if (count == 3) {
      positions.add(Offset(center.dx, center.dy - size / 2 - gap)); // Top
      positions.add(Offset(center.dx - size / 2 - gap / 2, center.dy + size / 2)); // Bottom Left
      positions.add(Offset(center.dx + size / 2 + gap / 2, center.dy + size / 2)); // Bottom Right
    }

    for (final pos in positions) {
      _drawStarShape(canvas, pos, size, paint);
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double size, Paint paint) {
    // 4-pointed star (stylized)
    final path = Path();
    final half = size / 2;
    final quarter = size / 4;
    
    path.moveTo(center.dx, center.dy - half); // Top
    path.lineTo(center.dx + quarter, center.dy - quarter);
    path.lineTo(center.dx + half, center.dy); // Right
    path.lineTo(center.dx + quarter, center.dy + quarter);
    path.lineTo(center.dx, center.dy + half); // Bottom
    path.lineTo(center.dx - quarter, center.dy + quarter);
    path.lineTo(center.dx - half, center.dy); // Left
    path.lineTo(center.dx - quarter, center.dy - quarter);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawOfficerStripes(Canvas canvas, Size size, Paint paint) {
    // Two vertical stripes along the edges? Or framing?
    // "Obszycie naramiennika" usually means a border.
    // But for "Młodszy brygadier" it's "2 belki".
    // In icons, it's often a border.
    
    final border = size.width * 0.1;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, border, size.height),
      paint..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - border, 0, border, size.height),
      paint..style = PaintingStyle.fill,
    );
  }

  void _drawGeneralZigzag(Canvas canvas, Size size, Paint paint) {
    // Wężyk generalski - zigzag border
    final path = Path();
    final w = size.width;
    final h = size.height;
    final step = 5.0;
    final amplitude = 3.0;
    
    // Draw along the border
    // Top
    /*
    path.moveTo(0, 0);
    for (double x = 0; x <= w; x += step) {
      path.lineTo(x, amplitude * (x / step % 2 == 0 ? 1 : -1));
    }
    */
    // Simplified: Just a thick patterned border
    final borderPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    canvas.drawRect(Rect.fromLTWH(2, 2, w-4, h-4), borderPaint);
    
    // Add zigzag detail if possible, but a thick border is a good approximation for small icons
  }

  void _drawAspirantInsignia(Canvas canvas, Offset center, double w, double h, int starCount, Paint paint) {
    // Draw V shape (Chevron pointing down)
    final vHeight = h * 0.25;
    final vWidth = w * 0.6;
    
    // V shape path
    final path = Path();
    path.moveTo(center.dx - vWidth / 2, center.dy - vHeight / 2); // Top Left
    path.lineTo(center.dx, center.dy + vHeight / 2); // Bottom Center
    path.lineTo(center.dx + vWidth / 2, center.dy - vHeight / 2); // Top Right
    
    // Use stroke paint for V
    final strokePaint = Paint()
      ..shader = paint.shader
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, strokePaint);
    
    // Draw stars inside the V (above the bottom vertex)
    // Adjust center for stars to be "inside" the V
    final starCenterY = center.dy - vHeight / 4;
    
    // Reuse _drawStars but maybe scale down if needed?
    // _drawStars uses w*0.2 for size. That fits.
    _drawStars(canvas, Offset(center.dx, starCenterY), w, h, starCount, paint);
  }

  @override
  bool shouldRepaint(covariant RankPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
