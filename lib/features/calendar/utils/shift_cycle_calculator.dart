import 'package:iskra/features/auth/domain/models/user_profile.dart';

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

class ShiftCycleCalculator {
  ShiftCycleCalculator({
    DateTime? anchorDate,
    this.anchorShiftId = 2,
  }) : anchorDate = anchorDate ?? defaultAnchorDate;

  final DateTime anchorDate;
  final int anchorShiftId;

  static final DateTime defaultAnchorDate = DateTime(2025, 11, 1);

  int shiftOn(DateTime date) {
    final target = _dateOnly(date);
    final anchor = _dateOnly(anchorDate);
    final difference = target.difference(anchor).inDays;
    final rotation = ((difference % 3) + 3) % 3;
    final shiftIndex = (anchorShiftId - 1 + rotation) % 3;
    return shiftIndex + 1;
  }

  ShiftAssignment? assignmentForDate(
    DateTime date,
    List<ShiftAssignment> sortedHistory,
  ) {
    final target = _dateOnly(date);
    ShiftAssignment? active;
    for (final assignment in sortedHistory) {
      final start = _dateOnly(assignment.startDate);
      if (start.isAfter(target)) {
        break;
      }
      active = assignment;
    }
    return active;
  }

  bool isScheduledDayForUser(
    DateTime date,
    List<ShiftAssignment> sortedHistory,
  ) {
    final assignment = assignmentForDate(date, sortedHistory);
    if (assignment == null) {
      return false;
    }
    return shiftOn(date) == assignment.shiftId;
  }
}
