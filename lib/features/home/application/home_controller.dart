import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';

class HomeState {
  const HomeState({
    required this.visibleMonth,
    required this.isEditingSchedule,
  });

  factory HomeState.initial() {
    final now = DateTime.now();
    return HomeState(
      visibleMonth: DateTime(now.year, now.month),
      isEditingSchedule: false,
    );
  }

  final DateTime visibleMonth;
  final bool isEditingSchedule;

  HomeState copyWith({DateTime? visibleMonth, bool? isEditingSchedule}) {
    return HomeState(
      visibleMonth: visibleMonth ?? this.visibleMonth,
      isEditingSchedule: isEditingSchedule ?? this.isEditingSchedule,
    );
  }
}

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    return HomeState.initial();
  }

  void setVisibleMonth(DateTime month) {
    state = state.copyWith(
      visibleMonth: DateTime(month.year, month.month),
    );
  }

  void toggleScheduleEditing() {
    state = state.copyWith(isEditingSchedule: !state.isEditingSchedule);
  }

  void goToPreviousMonth() {
    final current = state.visibleMonth;
    setVisibleMonth(DateTime(current.year, current.month - 1));
  }

  void goToNextMonth() {
    final current = state.visibleMonth;
    setVisibleMonth(DateTime(current.year, current.month + 1));
  }

  Future<void> saveDayNote({
    required String userId,
    required DateTime day,
    required String note,
  }) async {
    final repository = ref.read(calendarEntryRepositoryProvider);
    await repository.updateDayNote(
      userId: userId,
      day: day,
      note: note,
    );
  }

  Future<void> assignScheduledService({
    required String userId,
    required DateTime day,
    double scheduledHours = 24,
  }) async {
    final repository = ref.read(calendarEntryRepositoryProvider);
    await repository.assignScheduledService(
      userId: userId,
      day: day,
      scheduledHours: scheduledHours,
    );
  }

  Future<void> removeScheduledService({
    required String userId,
    required DateTime day,
  }) async {
    final repository = ref.read(calendarEntryRepositoryProvider);
    await repository.removeScheduledService(
      userId: userId,
      day: day,
    );
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
