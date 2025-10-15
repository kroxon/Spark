import 'package:flutter/material.dart';

/// Central palette for the burgundy themed interface.
class AppColors {
  static const Color primary = Color(0xFF7B1025);
  static const Color secondary = Color(0xFFB21C35);
  static const Color backgroundDark = Color(0xFF2B0A14);
  static const Color backgroundMid = Color(0xFF4A0E20);
  static const Color backgroundLight = Color(0xFF701123);
  static const Color surface = Color(0xFFF7F5F5);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [backgroundDark, backgroundMid, backgroundLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
