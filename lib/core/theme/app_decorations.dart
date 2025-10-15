import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Collection of reusable decorations and shapes for consistent styling.
class AppDecorations {
  const AppDecorations._();

  static BoxDecoration elevatedSurface({double radius = 28}) {
    return BoxDecoration(
      color: AppColors.surface.withOpacity(0.96),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
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
