import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_theme_type.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';

class UserProfile {
  static const double defaultOvertimeIndicatorThresholdHours = 24;

  final String uid;
  final String email;
  final String subscriptionPlan;
  final List<ShiftAssignment> shiftHistory;
  final double standardVacationHours; // Urlop wypoczynkowy (etatowy)
  final double additionalVacationHours; // Urlop dodatkowy
  final ShiftColorPalette shiftColorPalette;
  final ThemeMode themeMode;
  final AppThemeType appTheme;
  final double overtimeIndicatorThresholdHours;
  final Color onDutyIndicatorColor;

  UserProfile({
    required this.uid,
    required this.email,
    required this.subscriptionPlan,
    required this.shiftHistory,
    required this.standardVacationHours,
    required this.additionalVacationHours,
    ShiftColorPalette? shiftColorPalette,
    this.overtimeIndicatorThresholdHours =
        UserProfile.defaultOvertimeIndicatorThresholdHours,
    this.themeMode = ThemeMode.light,
    this.appTheme = AppThemeType.defaultRed,
    Color? onDutyIndicatorColor,
  })  : shiftColorPalette = shiftColorPalette ?? ShiftColorPalette.defaults,
        onDutyIndicatorColor =
            onDutyIndicatorColor ?? Colors.yellow.shade400;

  bool get isOnboardingComplete => shiftHistory.isNotEmpty;
}

class ShiftAssignment {
  final int shiftId; // Numer zmiany (1, 2, lub 3)
  final DateTime startDate; // Data, od której ten przydział obowiązuje

  ShiftAssignment({required this.shiftId, required this.startDate});
}
