import 'package:flutter/material.dart';

class ShiftColorPalette {
  const ShiftColorPalette({
    required this.shift1,
    required this.shift2,
    required this.shift3,
  });

  final Color shift1;
  final Color shift2;
  final Color shift3;

  static const ShiftColorPalette defaults = ShiftColorPalette(
    shift1: Color(0xFF1E88E5),
    shift2: Color(0xFF43A047),
    shift3: Color(0xFFF4511E),
  );

  Color colorForShift(int shiftId) {
    switch (shiftId) {
      case 1:
        return shift1;
      case 2:
        return shift2;
      case 3:
        return shift3;
      default:
        return shift1;
    }
  }

  ShiftColorPalette copyWith({
    Color? shift1,
    Color? shift2,
    Color? shift3,
  }) {
    return ShiftColorPalette(
      shift1: shift1 ?? this.shift1,
      shift2: shift2 ?? this.shift2,
      shift3: shift3 ?? this.shift3,
    );
  }
}
