import 'package:flutter/material.dart';

enum AppThemeType {
  defaultRed,
  oceanBlue,
  forestGreen,
  sunsetOrange;

  String get label {
    switch (this) {
      case AppThemeType.defaultRed:
        return 'Domyślny (Burgund)';
      case AppThemeType.oceanBlue:
        return 'Oceaniczny Błękit';
      case AppThemeType.forestGreen:
        return 'Leśna Zieleń';
      case AppThemeType.sunsetOrange:
        return 'Zachód Słońca';
    }
  }

  Color get seedColor {
    switch (this) {
      case AppThemeType.defaultRed:
        return const Color(0xFF7B1025);
      case AppThemeType.oceanBlue:
        return const Color(0xFF006994);
      case AppThemeType.forestGreen:
        return const Color(0xFF2E8B57);
      case AppThemeType.sunsetOrange:
        return const Color(0xFFFD5E53);
    }
  }
}
