import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Theme extension for styling the custom bottom navigation (GNav).
@immutable
class BottomNavColors extends ThemeExtension<BottomNavColors> {
  const BottomNavColors({
    required this.background,
    required this.tabBackground,
    required this.activeColor,
    required this.inactiveColor,
    this.elevation = 3,
    this.containerRadius = 16,
    this.tabRadius = 12,
  });

  final Color background;
  final Color tabBackground;
  final Color activeColor;
  final Color inactiveColor;
  final double elevation;
  final double containerRadius;
  final double tabRadius;

  /// A darker style used in both light and dark themes to emphasize the nav.
  factory BottomNavColors.darkOnLight() => const BottomNavColors(
        // Iskra brand-inspired: warm burgundy base with ember pill
        background: Color(0xFF5C1323), // deep brand burgundy (lighter than near-black)
        tabBackground: Color(0xFF8B2339), // glowing ember pill
        activeColor: Color(0xFFFFFFFF),
        inactiveColor: Color(0xFFEFD3D9), // soft rose-tinted near-white
        elevation: 3,
        containerRadius: 16,
        tabRadius: 12,
      );

  /// A slightly adjusted darker style for dark theme (keeps it dark and rich).
  factory BottomNavColors.darkOnDark() => const BottomNavColors(
        // Dark mode variant keeps color, avoids flat black
        background: Color(0xFF45101E),
        tabBackground: AppColors.primary, // strong brand accent
        activeColor: Color(0xFFFFFFFF),
        inactiveColor: Color(0xCCFFFFFF), // ~80% white for better legibility
        elevation: 2,
        containerRadius: 16,
        tabRadius: 12,
      );

  @override
  BottomNavColors copyWith({
    Color? background,
    Color? tabBackground,
    Color? activeColor,
    Color? inactiveColor,
    double? elevation,
    double? containerRadius,
    double? tabRadius,
  }) {
    return BottomNavColors(
      background: background ?? this.background,
      tabBackground: tabBackground ?? this.tabBackground,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      elevation: elevation ?? this.elevation,
      containerRadius: containerRadius ?? this.containerRadius,
      tabRadius: tabRadius ?? this.tabRadius,
    );
  }

  @override
  BottomNavColors lerp(ThemeExtension<BottomNavColors>? other, double t) {
    if (other is! BottomNavColors) return this;
    return BottomNavColors(
      background: Color.lerp(background, other.background, t) ?? background,
      tabBackground: Color.lerp(tabBackground, other.tabBackground, t) ?? tabBackground,
      activeColor: Color.lerp(activeColor, other.activeColor, t) ?? activeColor,
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t) ?? inactiveColor,
      elevation: lerpDouble(elevation, other.elevation, t),
      containerRadius: lerpDouble(containerRadius, other.containerRadius, t),
      tabRadius: lerpDouble(tabRadius, other.tabRadius, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
