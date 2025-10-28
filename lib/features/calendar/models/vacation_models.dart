import 'package:iskra/features/calendar/models/calendar_entry.dart';

enum VacationType { regular, additional }

class ConflictDay {
  const ConflictDay(this.date, this.events);

  final DateTime date;
  final List<DayEvent> events;

  String get formattedDate => '${date.day}.${date.month}.${date.year}';
}

enum ConflictResolution {
  cancel,
  clearAndAddVacation,
}

class VacationState {
  const VacationState({
    required this.isLoading,
  });

  const VacationState.initial() : isLoading = false;

  final bool isLoading;

  VacationState copyWith({
    bool? isLoading,
  }) {
    return VacationState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}