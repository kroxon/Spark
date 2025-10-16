import 'package:iskra/features/calendar/models/shift_color_palette.dart';

class UserProfile {
  final String uid;
  final String email;
  final String subscriptionPlan;
  final List<ShiftAssignment> shiftHistory;
  final double standardVacationHours; // Urlop wypoczynkowy (etatowy)
  final double additionalVacationHours; // Urlop dodatkowy
  final ShiftColorPalette shiftColorPalette;

  UserProfile({
    required this.uid,
    required this.email,
    required this.subscriptionPlan,
    required this.shiftHistory,
    required this.standardVacationHours,
    required this.additionalVacationHours,
    ShiftColorPalette? shiftColorPalette,
  }) : shiftColorPalette = shiftColorPalette ?? ShiftColorPalette.defaults;
}

class ShiftAssignment {
  final int shiftId; // Numer zmiany (1, 2, lub 3)
  final DateTime startDate; // Data, od której ten przydział obowiązuje

  ShiftAssignment({
    required this.shiftId,
    required this.startDate,
  });
}