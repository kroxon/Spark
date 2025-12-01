import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Collection of reusable decorations and shapes for consistent styling.
class AppDecorations {
  const AppDecorations._();

  static BoxDecoration elevatedSurface({
    double radius = 28,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? AppColors.surface).withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 32,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }

  static ShapeBorder dialogShape({double radius = 20}) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
