import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';

class HomeState {
  const HomeState({required this.visibleMonth});

  factory HomeState.initial() {
    final now = DateTime.now();
    return HomeState(visibleMonth: DateTime(now.year, now.month));
  }

  final DateTime visibleMonth;

  HomeState copyWith({DateTime? visibleMonth}) {
    return HomeState(
      visibleMonth: visibleMonth ?? this.visibleMonth,
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
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
