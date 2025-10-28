import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/incident_entry.dart';

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
    state = state.copyWith(visibleMonth: DateTime(month.year, month.month));
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

  Future<void> saveDayDetails({
    required String userId,
    required DateTime day,
    required List<DayEvent> events,
    required List<IncidentEntry> incidents,
    required String generalNote,
    double? scheduledHours,
  }) async {
    // Get current entry to calculate vacation hours changes
    final repository = ref.read(calendarEntryRepositoryProvider);
    final userProfileRepository = ref.read(userProfileRepositoryProvider);

    final existingEntry = await repository.getEntryForDay(userId, day);

    // Calculate vacation hours changes
    final vacationHoursChange = _calculateVacationHoursChange(
      existingEntry: existingEntry,
      newEvents: events,
      scheduledHours: scheduledHours,
    );

    // Save the day details
    await repository.saveDayDetails(
      userId: userId,
      day: day,
      events: events,
      incidents: incidents,
      note: generalNote,
      scheduledHours: scheduledHours,
    );

    // Update vacation hours if there were changes
    if (vacationHoursChange != (0.0, 0.0)) {
      final currentProfile = await userProfileRepository.watchProfile(userId).first;
      if (currentProfile != null) {
        final newStandardHours = (currentProfile.standardVacationHours + vacationHoursChange.$1).clamp(0.0, double.infinity);
        final newAdditionalHours = (currentProfile.additionalVacationHours + vacationHoursChange.$2).clamp(0.0, double.infinity);

        await userProfileRepository.updateVacationHours(
          uid: userId,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }
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
    await repository.removeScheduledService(userId: userId, day: day);
  }

  (double, double) _calculateVacationHoursChange({
    required CalendarEntry? existingEntry,
    required List<DayEvent> newEvents,
    required double? scheduledHours,
  }) {
    // Calculate existing vacation hours
    final existingStandardVacation = existingEntry?.events
        .where((event) => event.type == EventType.vacationRegular)
        .fold<double>(0, (sum, event) => sum + event.hours) ?? 0;

    final existingAdditionalVacation = existingEntry?.events
        .where((event) => event.type == EventType.vacationAdditional)
        .fold<double>(0, (sum, event) => sum + event.hours) ?? 0;

    // Calculate new vacation hours (limited by scheduled hours)
    final scheduledHoursLimit = scheduledHours ?? existingEntry?.scheduledHours ?? 0;

    final newStandardVacation = newEvents
        .where((event) => event.type == EventType.vacationRegular)
        .fold<double>(0, (sum, event) => sum + event.hours);

    final newAdditionalVacation = newEvents
        .where((event) => event.type == EventType.vacationAdditional)
        .fold<double>(0, (sum, event) => sum + event.hours);

    // Apply the rule: vacation hours cannot exceed scheduled hours
    final effectiveNewStandard = scheduledHoursLimit > 0 ? newStandardVacation.clamp(0, scheduledHoursLimit) : 0;
    final effectiveNewAdditional = scheduledHoursLimit > 0 ? newAdditionalVacation.clamp(0, scheduledHoursLimit) : 0;

    // Calculate the change (negative means hours were consumed, positive means hours were restored)
    final standardChange = existingStandardVacation - effectiveNewStandard;
    final additionalChange = existingAdditionalVacation - effectiveNewAdditional;

    return (standardChange, additionalChange);
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
