import 'package:iskra/features/calendar/models/calendar_entry.dart';

enum SickLeaveType { eightyPercent, hundredPercent }

class ConflictDay {
  const ConflictDay(this.date, this.events);

  final DateTime date;
  final List<DayEvent> events;

  String get formattedDate => '${date.day}.${date.month}.${date.year}';
}

enum ConflictResolution {
  cancel,
  clearAndAddSickLeave,
}

class SickLeaveState {
  const SickLeaveState({
    required this.isLoading,
  });

  const SickLeaveState.initial() : isLoading = false;

  final bool isLoading;

  SickLeaveState copyWith({
    bool? isLoading,
  }) {
    return SickLeaveState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}