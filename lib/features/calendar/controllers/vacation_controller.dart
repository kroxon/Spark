import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/vacation_models.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'package:iskra/features/calendar/widgets/vacation_dialog_components/vacation_conflict_dialog.dart';

class VacationController {
  final WidgetRef _ref;
  final BuildContext _context;
  bool _isLoading = false;

  VacationController(this._ref, this._context);

  bool get isLoading => _isLoading;

  Future<List<ConflictDay>> checkConflicts(DateTime startDate, DateTime endDate) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return [];

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final conflicts = <ConflictDay>[];

    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      if (existingEntry != null && existingEntry.events.isNotEmpty) {
        conflicts.add(ConflictDay(date, existingEntry.events));
      }
    }

    return conflicts;
  }

  Future<double> calculatePotentialHoursForRange(DateTime? startDate, DateTime? endDate, UserProfile userProfile) async {
    if (startDate == null || endDate == null) {
      return 0;
    }

    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      return 0;
    }

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final shiftCalculator = ShiftCycleCalculator();

    double totalConsumedHours = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      
      if (existingEntry != null) {
        // If we have an explicit entry, use its scheduled hours (even if 0)
        totalConsumedHours += existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
          date,
          userProfile.shiftHistory,
        );
        if (hasShiftSchedule) {
          totalConsumedHours += 24.0;
        }
      }
    }

    return totalConsumedHours;
  }

  /// Same as [calculatePotentialHoursForRange] but skips days listed in [conflicts].
  Future<double> calculatePotentialHoursForRangeExcludingConflicts(
    DateTime? startDate,
    DateTime? endDate,
    UserProfile userProfile,
    List<ConflictDay> conflicts,
  ) async {
    if (startDate == null || endDate == null) {
      return 0;
    }

    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      return 0;
    }

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final shiftCalculator = ShiftCycleCalculator();

    double totalConsumedHours = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      // Skip days with conflicts
      final hasConflict = conflicts.any((ConflictDay conflict) =>
        conflict.date.year == date.year &&
        conflict.date.month == date.month &&
        conflict.date.day == date.day);
      if (hasConflict) continue;

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      
      if (existingEntry != null) {
        // If we have an explicit entry, use its scheduled hours (even if 0)
        totalConsumedHours += existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
          date,
          userProfile.shiftHistory,
        );
        if (hasShiftSchedule) {
          totalConsumedHours += 24.0;
        }
      }
    }

    return totalConsumedHours;
  }

  Future<ConflictResolution> showConflictDialog(List<ConflictDay> conflicts) async {
    return await VacationConflictDialog.show(_context, conflicts: conflicts);
  }

  /// Returns list of dates in the given range that already contain events of the
  /// "secondary" vacation type (i.e. if primaryType is regular, checks for
  /// EventType.vacationAdditional). This helps to detect cases where secondary
  /// hours are already occupied by existing events in the schedule.
  Future<List<DateTime>> findDaysWithSecondaryVacationEvents(DateTime startDate, DateTime endDate, VacationType primaryType) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return [];

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final days = <DateTime>[];

    final secondaryEventType = primaryType == VacationType.regular ? EventType.vacationAdditional : EventType.vacationRegular;

    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate; date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime); date = date.add(const Duration(days: 1))) {
      final existingEntry = await repository.getEntryForDay(user.uid, date);
      if (existingEntry != null) {
        final hasSecondary = existingEntry.events.any((e) => e.type == secondaryEventType && e.hours > 0);
        if (hasSecondary) days.add(date);
      }
    }

    return days;
  }

  /// Calculate how many vacation hours would be restored if existing vacation
  /// events in the given range were cleared. Returns a map with keys
  /// 'standard' and 'additional'. This mirrors the restore logic in
  /// `_clearExistingStatusesAndAddVacation`.
  Future<Map<String, double>> computeRestoredHoursForRange(DateTime startDate, DateTime endDate) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return {'standard': 0.0, 'additional': 0.0};

    final repository = _ref.read(calendarEntryRepositoryProvider);
    double hoursToRestoreStandard = 0.0;
    double hoursToRestoreAdditional = 0.0;

    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate; date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime); date = date.add(const Duration(days: 1))) {
      final existingEntry = await repository.getEntryForDay(user.uid, date);
      if (existingEntry != null) {
        final scheduledHours = existingEntry.scheduledHours;
        if (scheduledHours > 0) {
          for (final event in existingEntry.events) {
            if (event.type == EventType.vacationRegular) {
              hoursToRestoreStandard += event.hours;
            } else if (event.type == EventType.vacationAdditional) {
              hoursToRestoreAdditional += event.hours;
            }
          }
        }
      }
    }

    return {
      'standard': hoursToRestoreStandard,
      'additional': hoursToRestoreAdditional,
    };
  }

  /// Save a vacation.
  /// If [secondaryToUse] > 0 the controller will consume that many hours
  /// from the other vacation balance in order to top up the primary one.
  Future<void> saveVacation({
    required DateTime startDate,
    required DateTime endDate,
    required VacationType vacationType,
    required List<ConflictDay> conflicts,
    double secondaryToUse = 0.0,
  }) async {
  _isLoading = true;
  debugPrint('[VacationController] saveVacation start: $startDate -> $endDate, type=$vacationType, secondaryToUse=$secondaryToUse');

    try {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      // Handle different resolution types
      if (conflicts.isNotEmpty) {
        final resolution = await showConflictDialog(conflicts);
        debugPrint('[VacationController] Conflicts found: ${conflicts.length}, user chose $resolution');
        if (resolution == ConflictResolution.cancel) {
          _isLoading = false;
          return;
        }

        if (resolution == ConflictResolution.clearAndAddVacation) {
          debugPrint('[VacationController] clearAndAddVacation chosen - will clear and add vacation (secondaryToUse=$secondaryToUse)');
          await _clearExistingStatusesAndAddVacation(startDate, endDate, vacationType, conflicts, secondaryToUse: secondaryToUse);
          _isLoading = false;
          return;
        }
      }

  debugPrint('[VacationController] No conflicts or proceeding to save directly (secondaryToUse=$secondaryToUse)');
  await _saveVacationDirect(startDate, endDate, vacationType, conflicts, secondaryToUse: secondaryToUse);

      // Note: Do not pop the UI or show SnackBars from the controller —
      // navigation and user feedback should be handled by the UI layer
      // (VacationDialog). This prevents double pops / unexpected route
      // closures when the dialog also closes itself.
    } catch (e) {
      // Don't interact with UI from the controller. Log and rethrow so the
      // UI layer (dialog) can show SnackBars / navigate. This avoids
      // use_build_context_synchronously issues and double navigation.
      debugPrint('[VAC_CTRL][ERROR] saveVacation failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _saveVacationDirect(DateTime startDate, DateTime endDate, VacationType vacationType, List<ConflictDay> conflicts, {double secondaryToUse = 0.0}) async {
    debugPrint('[VAC_CTRL] _saveVacationDirect START ${DateTime.now().toIso8601String()} for $startDate -> $endDate, type=$vacationType, secondaryToUse=$secondaryToUse');
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final userProfileRepository = _ref.read(userProfileRepositoryProvider);
    final shiftCalculator = ShiftCycleCalculator();

    // Get user profile for shift calculations
    final userProfile = await userProfileRepository.watchProfile(user.uid).first;
    if (userProfile == null) {
      throw Exception('Nie udało się pobrać profilu użytkownika');
    }

  // Calculate total vacation hours that will be consumed (skipping conflicts)
  double totalConsumedHours = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    // First pass: check existing entries and calculate consumption
    int dayIndex = 0;
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {
      dayIndex++;
      debugPrint('[VAC_CTRL] checking day $dayIndex: ${date.toIso8601String()}');

  final existingEntry = await repository.getEntryForDay(user.uid, date);
  debugPrint('[VAC_CTRL] got entry for ${date.toIso8601String()}: scheduledHours=${existingEntry?.scheduledHours} events=${existingEntry?.events.length ?? 0}');
      
      // Skip days with conflicts
      final hasConflict = conflicts.any((ConflictDay conflict) =>
        conflict.date.year == date.year &&
        conflict.date.month == date.month &&
        conflict.date.day == date.day);
      if (hasConflict) {
        continue;
      }

      double consumedOnThisDay;
      if (existingEntry != null) {
        // If entry exists, use its scheduled hours (even if 0)
        consumedOnThisDay = existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
          date,
          userProfile.shiftHistory,
        );
        consumedOnThisDay = hasShiftSchedule ? 24.0 : 0.0;
      }
      
      totalConsumedHours += consumedOnThisDay;
    }
    debugPrint('[VacationController] _saveVacationDirect totalConsumedHours (excluding conflicts) = $totalConsumedHours');
    // Determine primary and secondary balances depending on selected type
    final currentProfile = await userProfileRepository.watchProfile(user.uid).first;
    if (currentProfile == null) {
      throw Exception('Nie udało się pobrać profilu użytkownika');
    }

    double primaryAvailable = vacationType == VacationType.regular
        ? currentProfile.standardVacationHours
        : currentProfile.additionalVacationHours;

    double secondaryAvailable = vacationType == VacationType.regular
        ? currentProfile.additionalVacationHours
        : currentProfile.standardVacationHours;

    // If primary covers everything, ignore secondaryToUse. If not, ensure combined suffices.
    if (primaryAvailable < totalConsumedHours) {
      if (primaryAvailable + secondaryAvailable < totalConsumedHours) {
        debugPrint('[VacationController] Insufficient combined balance: primary=$primaryAvailable, secondary=$secondaryAvailable, required=$totalConsumedHours');
        throw Exception('Brak wystarczających godzin urlopu (dostępne łącznie: ${primaryAvailable + secondaryAvailable}, wymagane: $totalConsumedHours)');
      }

      // If caller didn't specify how much to use from secondary, compute minimal needed
      if (secondaryToUse <= 0.0) {
        secondaryToUse = totalConsumedHours - primaryAvailable;
      }
    } else {
      // primary covers all
      secondaryToUse = 0.0;
    }

  debugPrint('[VacationController] Allocation start: primaryAvailable=$primaryAvailable, secondaryAvailable=$secondaryAvailable, secondaryToUse=$secondaryToUse');
  // Prepare running balances for allocation
    double remainingPrimary = primaryAvailable;
    double remainingSecondary = secondaryAvailable;
    double consumedFromPrimary = 0.0;
    double consumedFromSecondary = 0.0;

    // Save vacation for each day in the range, allocating hours between primary and secondary
    int saveIndex = 0;
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {
      saveIndex++;
      debugPrint('[VAC_CTRL] allocating for day $saveIndex: ${date.toIso8601String()} (toAllocate start)');

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      
      // Check if it is a shift day according to the cycle
      final isShiftDay = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      double vacationHours;
      if (existingEntry != null) {
        // If entry exists, use its scheduled hours (even if 0)
        vacationHours = existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        vacationHours = isShiftDay ? 24.0 : 0.0;
      }

      double toAllocate = vacationHours;
      final events = <DayEvent>[];

      if (toAllocate > 0) {
        // Allocate from primary first
        final useFromPrimary = remainingPrimary >= toAllocate ? toAllocate : remainingPrimary;
        if (useFromPrimary > 0) {
          events.add(DayEvent(
            type: vacationType == VacationType.regular ? EventType.vacationRegular : EventType.vacationAdditional,
            hours: useFromPrimary,
          ));
          remainingPrimary -= useFromPrimary;
          consumedFromPrimary += useFromPrimary;
          toAllocate -= useFromPrimary;
        }

        // If still need hours, allocate from secondary
        if (toAllocate > 0) {
          final secondaryEventType = vacationType == VacationType.regular ? EventType.vacationAdditional : EventType.vacationRegular;
          final useFromSecondary = remainingSecondary >= toAllocate ? toAllocate : remainingSecondary;
          if (useFromSecondary > 0) {
            events.add(DayEvent(
              type: secondaryEventType,
              hours: useFromSecondary,
            ));
            remainingSecondary -= useFromSecondary;
            consumedFromSecondary += useFromSecondary;
            toAllocate -= useFromSecondary;
          }
        }
      } else {
        // Do not add 0h event for days off
        // BUT if it is a shift day (even if hours are 0 due to manual override), mark it
        if (isShiftDay) {
          events.add(DayEvent(
            type: vacationType == VacationType.regular ? EventType.vacationRegular : EventType.vacationAdditional,
            hours: 0,
          ));
        }
      }

      if (toAllocate > 0) {
        // Shouldn't happen due to earlier checks, but guard anyway
        debugPrint('[VacationController] Allocation failed for day ${date.toIso8601String()}, remainingPrimary=$remainingPrimary, remainingSecondary=$remainingSecondary, toAllocate=$toAllocate');
        throw Exception('Brak wystarczających godzin do zaalokowania dla dnia ${date.toIso8601String()}');
      }

      try {
        await repository.saveDayDetails(
          userId: user.uid,
          day: date,
          events: events,
          incidents: const [],
          note: '',
          scheduledHours: null, // Don't change scheduled hours
        );
        debugPrint('[VAC_CTRL] saved day $saveIndex: ${date.toIso8601String()} events=${events.map((e) => '${e.type}:${e.hours}').join(',')}');
      } catch (e) {
        debugPrint('[VAC_CTRL][ERROR] failed saving day ${date.toIso8601String()}: $e');
        rethrow;
      }
    }

    debugPrint('[VacationController] Allocation finished: consumedFromPrimary=$consumedFromPrimary, consumedFromSecondary=$consumedFromSecondary');
    // Update vacation hours in user profile with consumedFromPrimary/Secondary
  if (consumedFromPrimary > 0 || consumedFromSecondary > 0) {
      final latestProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (latestProfile != null) {
        double newStandardHours;
        double newAdditionalHours;

        if (vacationType == VacationType.regular) {
          // primary = standard
          newStandardHours = (latestProfile.standardVacationHours - consumedFromPrimary).clamp(0.0, double.infinity);
          newAdditionalHours = (latestProfile.additionalVacationHours - consumedFromSecondary).clamp(0.0, double.infinity);
        } else {
          // primary = additional
          newAdditionalHours = (latestProfile.additionalVacationHours - consumedFromPrimary).clamp(0.0, double.infinity);
          newStandardHours = (latestProfile.standardVacationHours - consumedFromSecondary).clamp(0.0, double.infinity);
        }

        debugPrint('[VacationController] Updating profile hours: newStandardHours=$newStandardHours, newAdditionalHours=$newAdditionalHours');
        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }
    debugPrint('[VAC_CTRL] _saveVacationDirect END consumedFromPrimary=$consumedFromPrimary consumedFromSecondary=$consumedFromSecondary ${DateTime.now().toIso8601String()}');
  }

  Future<void> _clearExistingStatusesAndAddVacation(DateTime startDate, DateTime endDate, VacationType vacationType, List<ConflictDay> conflicts, {double secondaryToUse = 0.0}) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    debugPrint('[VacationController] _clearExistingStatusesAndAddVacation start: $startDate -> $endDate, type=$vacationType, secondaryToUse=$secondaryToUse');

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final userProfileRepository = _ref.read(userProfileRepositoryProvider);
    final shiftCalculator = ShiftCycleCalculator();

    // Get user profile for shift calculations
    final userProfile = await userProfileRepository.watchProfile(user.uid).first;
    if (userProfile == null) {
      throw Exception('Nie udało się pobrać profilu użytkownika');
    }

  // First, restore vacation hours from ALL existing vacation events in the range that will be cleared
    double hoursToRestoreStandard = 0;
    double hoursToRestoreAdditional = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    // Check all days in the range for existing vacations
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      if (existingEntry != null) {
        for (final event in existingEntry.events) {
          if (event.type == EventType.vacationRegular || event.type == EventType.vacationAdditional) {
            // Check if this day has scheduled hours (only then vacation hours were consumed)
            final scheduledHours = existingEntry.scheduledHours;
            if (scheduledHours > 0) {
              if (event.type == EventType.vacationRegular) {
                hoursToRestoreStandard += event.hours;
              } else if (event.type == EventType.vacationAdditional) {
                hoursToRestoreAdditional += event.hours;
              }
            }
          }
        }
      }
    }

  // Restore vacation hours to user profile
  debugPrint('[VAC_CTRL] restore totals before clear: standard=$hoursToRestoreStandard additional=$hoursToRestoreAdditional');
  if (hoursToRestoreStandard > 0 || hoursToRestoreAdditional > 0) {
      final currentProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (currentProfile != null) {
        final newStandardHours = (currentProfile.standardVacationHours + hoursToRestoreStandard).clamp(0.0, double.infinity);
        final newAdditionalHours = (currentProfile.additionalVacationHours + hoursToRestoreAdditional).clamp(0.0, double.infinity);

        debugPrint('[VAC_CTRL] Restoring hours before clear: +standard=$hoursToRestoreStandard, +additional=$hoursToRestoreAdditional -> newStandard=$newStandardHours, newAdditional=$newAdditionalHours');
        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }

  // Clear ALL days in the range (not just conflict days)
  debugPrint('[VAC_CTRL] Clearing days in range $currentDate -> $endDateTime');
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      try {
        await repository.saveDayDetails(
          userId: user.uid,
          day: date,
          events: [], // Clear all events
          incidents: const [],
          note: '',
          scheduledHours: null, // Don't change scheduled hours
        );
        debugPrint('[VAC_CTRL] cleared day ${date.toIso8601String()}');
      } catch (e) {
        debugPrint('[VAC_CTRL][ERROR] failed clearing day ${date.toIso8601String()}: $e');
        rethrow;
      }
    }

  // Calculate total vacation hours that will be consumed (for entire range)
    double totalConsumedHours = 0;
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      
      double consumedOnThisDay;
      if (existingEntry != null) {
        // If entry exists, use its scheduled hours (even if 0)
        consumedOnThisDay = existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
          date,
          userProfile.shiftHistory,
        );
        consumedOnThisDay = hasShiftSchedule ? 24.0 : 0.0;
      }
      
      totalConsumedHours += consumedOnThisDay;
    }

  // After restoring and clearing, read latest profile to get up-to-date balances
    final latestProfileAfterRestore = await userProfileRepository.watchProfile(user.uid).first;
    if (latestProfileAfterRestore == null) {
      throw Exception('Nie udało się pobrać profilu użytkownika');
    }

    double primaryAvailable = vacationType == VacationType.regular
        ? latestProfileAfterRestore.standardVacationHours
        : latestProfileAfterRestore.additionalVacationHours;

    double secondaryAvailable = vacationType == VacationType.regular
        ? latestProfileAfterRestore.additionalVacationHours
        : latestProfileAfterRestore.standardVacationHours;

    if (primaryAvailable < totalConsumedHours) {
      if (primaryAvailable + secondaryAvailable < totalConsumedHours) {
        debugPrint('[VacationController] Insufficient combined balance after restore: primary=$primaryAvailable, secondary=$secondaryAvailable, required=$totalConsumedHours');
        throw Exception('Brak wystarczających godzin urlopu (dostępne łącznie: ${primaryAvailable + secondaryAvailable}, wymagane: $totalConsumedHours)');
      }

      if (secondaryToUse <= 0.0) {
        secondaryToUse = totalConsumedHours - primaryAvailable;
      }
    } else {
      secondaryToUse = 0.0;
    }

  debugPrint('[VAC_CTRL] clearExisting: allocation start: primaryAvailable=$primaryAvailable, secondaryAvailable=$secondaryAvailable, secondaryToUse=$secondaryToUse');
  // Allocate per-day between primary and secondary
    double remainingPrimary = primaryAvailable;
    double remainingSecondary = secondaryAvailable;
    double consumedFromPrimary = 0.0;
    double consumedFromSecondary = 0.0;

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      
      // Check if it is a shift day according to the cycle
      final isShiftDay = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      double vacationHours;
      if (existingEntry != null) {
        // If entry exists, use its scheduled hours (even if 0)
        vacationHours = existingEntry.scheduledHours;
      } else {
        // No entry - fallback to shift cycle
        vacationHours = isShiftDay ? 24.0 : 0.0;
      }

      double toAllocate = vacationHours;
      final events = <DayEvent>[];

      if (toAllocate > 0) {
        // Allocate from primary first
        final useFromPrimary = remainingPrimary >= toAllocate ? toAllocate : remainingPrimary;
        if (useFromPrimary > 0) {
          events.add(DayEvent(
            type: vacationType == VacationType.regular ? EventType.vacationRegular : EventType.vacationAdditional,
            hours: useFromPrimary,
          ));
          remainingPrimary -= useFromPrimary;
          consumedFromPrimary += useFromPrimary;
          toAllocate -= useFromPrimary;
        }

        // If still need hours, allocate from secondary
        if (toAllocate > 0) {
          final secondaryEventType = vacationType == VacationType.regular ? EventType.vacationAdditional : EventType.vacationRegular;
          final useFromSecondary = remainingSecondary >= toAllocate ? toAllocate : remainingSecondary;
          if (useFromSecondary > 0) {
            events.add(DayEvent(
              type: secondaryEventType,
              hours: useFromSecondary,
            ));
            remainingSecondary -= useFromSecondary;
            consumedFromSecondary += useFromSecondary;
            toAllocate -= useFromSecondary;
          }
        }
      } else {
        // Do not add 0h event for days off
        // BUT if it is a shift day (even if hours are 0 due to manual override), mark it
        if (isShiftDay) {
          events.add(DayEvent(
            type: vacationType == VacationType.regular ? EventType.vacationRegular : EventType.vacationAdditional,
            hours: 0,
          ));
        }
      }
      if (toAllocate > 0) {
        throw Exception('Brak wystarczających godzin do zaalokowania dla dnia ${date.toIso8601String()}');
      }

      try {
        await repository.saveDayDetails(
          userId: user.uid,
          day: date,
          events: events,
          incidents: const [],
          note: '',
          scheduledHours: null,
        );
        debugPrint('[VAC_CTRL] clearExisting saved day ${date.toIso8601String()} events=${events.map((e) => '${e.type}:${e.hours}').join(',')}');
      } catch (e) {
        debugPrint('[VAC_CTRL][ERROR] clearExisting failed saving day ${date.toIso8601String()}: $e');
        rethrow;
      }
    }

  debugPrint('[VAC_CTRL] clearExisting: allocation finished: consumedFromPrimary=$consumedFromPrimary, consumedFromSecondary=$consumedFromSecondary');
    // Update balances
    if (consumedFromPrimary > 0 || consumedFromSecondary > 0) {
      final latestProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (latestProfile != null) {
        double newStandardHours;
        double newAdditionalHours;

        if (vacationType == VacationType.regular) {
          newStandardHours = (latestProfile.standardVacationHours - consumedFromPrimary).clamp(0.0, double.infinity);
          newAdditionalHours = (latestProfile.additionalVacationHours - consumedFromSecondary).clamp(0.0, double.infinity);
        } else {
          newAdditionalHours = (latestProfile.additionalVacationHours - consumedFromPrimary).clamp(0.0, double.infinity);
          newStandardHours = (latestProfile.standardVacationHours - consumedFromSecondary).clamp(0.0, double.infinity);
        }

        debugPrint('[VacationController] clearExisting: updating profile hours: newStandardHours=$newStandardHours, newAdditionalHours=$newAdditionalHours');
        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }

    // Do not perform navigation/UI operations from the controller. UI layer
    // (VacationDialog) will handle success notifications and navigation.
    debugPrint('[VAC_CTRL] clearExisting finished ${DateTime.now().toIso8601String()}');
  }
}