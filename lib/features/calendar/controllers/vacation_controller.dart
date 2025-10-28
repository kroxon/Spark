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

      // Check if it's a weekend (Saturday = 6, Sunday = 7)
      if (date.weekday == 6 || date.weekday == 7) {
        continue; // Skip weekends for vacation
      }

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
      final scheduledHours = existingEntry?.scheduledHours ?? 0;

      // Check if user has scheduled service either manually (scheduledHours > 0)
      // or through their shift cycle
      final hasManualSchedule = scheduledHours > 0;
      final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      if (hasManualSchedule || hasShiftSchedule) {
        // User has service this day - consume vacation hours
        // Use scheduledHours if available, otherwise default to 24 hours for shift cycle
        final consumedOnThisDay = hasManualSchedule ? scheduledHours : 24.0;
        totalConsumedHours += consumedOnThisDay;
      }
      // If neither manual schedule nor shift schedule, consume 0 hours (day off)
    }

    return totalConsumedHours;
  }

  Future<ConflictResolution> showConflictDialog(List<ConflictDay> conflicts) async {
    return await VacationConflictDialog.show(_context, conflicts: conflicts);
  }

  Future<void> saveVacation({
    required DateTime startDate,
    required DateTime endDate,
    required VacationType vacationType,
    required List<ConflictDay> conflicts,
  }) async {
    _isLoading = true;

    try {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      // Handle different resolution types
      if (conflicts.isNotEmpty) {
        final resolution = await showConflictDialog(conflicts);
        if (resolution == ConflictResolution.cancel) {
          _isLoading = false;
          return;
        }

        if (resolution == ConflictResolution.clearAndAddVacation) {
          await _clearExistingStatusesAndAddVacation(startDate, endDate, vacationType, conflicts);
          _isLoading = false;
          return;
        }
      }

      await _saveVacationDirect(startDate, endDate, vacationType, conflicts);

      if (_context.mounted) {
        Navigator.of(_context).pop();
        ScaffoldMessenger.of(_context).showSnackBar(
          const SnackBar(content: Text('Urlop został dodany')),
        );
      }
    } catch (e) {
      if (_context.mounted) {
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(content: Text('Błąd podczas zapisywania: $e')),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _saveVacationDirect(DateTime startDate, DateTime endDate, VacationType vacationType, List<ConflictDay> conflicts) async {
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

    // Calculate total vacation hours that will be consumed
    double totalConsumedHours = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    // First pass: check existing entries and calculate consumption
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      final scheduledHours = existingEntry?.scheduledHours ?? 0;

      // Check if user has scheduled service either manually (scheduledHours > 0)
      // or through their shift cycle
      final hasManualSchedule = scheduledHours > 0;
      final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      // Skip days with conflicts
      final hasConflict = conflicts.any((ConflictDay conflict) =>
        conflict.date.year == date.year &&
        conflict.date.month == date.month &&
        conflict.date.day == date.day);
      if (hasConflict) {
        continue;
      }

      if (hasManualSchedule || hasShiftSchedule) {
        // User has service this day - consume vacation hours
        // Use scheduledHours if available, otherwise default to 24 hours for shift cycle
        final consumedOnThisDay = hasManualSchedule ? scheduledHours : 24.0;
        totalConsumedHours += consumedOnThisDay;
      }
    }

    // Save vacation for each day in the range
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      final scheduledHours = existingEntry?.scheduledHours ?? 0;

      // Check if user has scheduled service either manually (scheduledHours > 0)
      // or through their shift cycle
      final hasManualSchedule = scheduledHours > 0;
      final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      // Skip days with conflicts
      final hasConflict = conflicts.any((ConflictDay conflict) =>
        conflict.date.year == date.year &&
        conflict.date.month == date.month &&
        conflict.date.day == date.day);
      if (hasConflict) {
        continue;
      }

      // Create vacation event with appropriate hours for this day
      final eventType = vacationType == VacationType.regular
          ? EventType.vacationRegular
          : EventType.vacationAdditional;

      // Vacation hours: use scheduledHours if available, otherwise 24 hours for shift cycle, or 8 hours as fallback
      final vacationHours = hasManualSchedule
          ? scheduledHours
          : hasShiftSchedule
              ? 24.0
              : 8.0;

      final vacationEvent = DayEvent(
        type: eventType,
        hours: vacationHours,
      );

      await repository.saveDayDetails(
        userId: user.uid,
        day: date,
        events: [vacationEvent],
        incidents: const [],
        note: '',
        scheduledHours: null, // Don't change scheduled hours
      );
    }

    // Update vacation hours in user profile
    if (totalConsumedHours > 0) {
      final currentProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (currentProfile != null) {
        final newStandardHours = vacationType == VacationType.regular
            ? (currentProfile.standardVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.standardVacationHours;

        final newAdditionalHours = vacationType == VacationType.additional
            ? (currentProfile.additionalVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.additionalVacationHours;

        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }
  }

  Future<void> _clearExistingStatusesAndAddVacation(DateTime startDate, DateTime endDate, VacationType vacationType, List<ConflictDay> conflicts) async {
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
    if (hoursToRestoreStandard > 0 || hoursToRestoreAdditional > 0) {
      final currentProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (currentProfile != null) {
        final newStandardHours = (currentProfile.standardVacationHours + hoursToRestoreStandard).clamp(0.0, double.infinity);
        final newAdditionalHours = (currentProfile.additionalVacationHours + hoursToRestoreAdditional).clamp(0.0, double.infinity);

        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }

    // Clear ALL days in the range (not just conflict days)
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      await repository.saveDayDetails(
        userId: user.uid,
        day: date,
        events: [], // Clear all events
        incidents: const [],
        note: '',
        scheduledHours: null, // Don't change scheduled hours
      );
    }

    // Calculate total vacation hours that will be consumed
    double totalConsumedHours = 0;
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      final scheduledHours = existingEntry?.scheduledHours ?? 0;

      // Check if user has scheduled service either manually (scheduledHours > 0)
      // or through their shift cycle
      final hasManualSchedule = scheduledHours > 0;
      final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      if (hasManualSchedule || hasShiftSchedule) {
        // User has service this day - consume vacation hours
        // Use scheduledHours if available, otherwise default to 24 hours for shift cycle
        final consumedOnThisDay = hasManualSchedule ? scheduledHours : 24.0;
        totalConsumedHours += consumedOnThisDay;
      }
    }

    // Save vacation for each day in the range
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      final existingEntry = await repository.getEntryForDay(user.uid, date);
      final scheduledHours = existingEntry?.scheduledHours ?? 0;

      // Check if user has scheduled service either manually (scheduledHours > 0)
      // or through their shift cycle
      final hasManualSchedule = scheduledHours > 0;
      final hasShiftSchedule = shiftCalculator.isScheduledDayForUser(
        date,
        userProfile.shiftHistory,
      );

      // Create vacation event with appropriate hours for this day
      final eventType = vacationType == VacationType.regular
          ? EventType.vacationRegular
          : EventType.vacationAdditional;

      // Vacation hours: use scheduledHours if available, otherwise 24 hours for shift cycle, or 8 hours as fallback
      final vacationHours = hasManualSchedule
          ? scheduledHours
          : hasShiftSchedule
              ? 24.0
              : 8.0;

      final vacationEvent = DayEvent(
        type: eventType,
        hours: vacationHours,
      );

      await repository.saveDayDetails(
        userId: user.uid,
        day: date,
        events: [vacationEvent],
        incidents: const [],
        note: '',
        scheduledHours: null, // Don't change scheduled hours
      );
    }

    // Update vacation hours in user profile
    if (totalConsumedHours > 0) {
      final currentProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (currentProfile != null) {
        final newStandardHours = vacationType == VacationType.regular
            ? (currentProfile.standardVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.standardVacationHours;

        final newAdditionalHours = vacationType == VacationType.additional
            ? (currentProfile.additionalVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.additionalVacationHours;

        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    }

    if (_context.mounted) {
      Navigator.of(_context).pop();
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(content: Text('Urlop został dodany (istniejące statusy zostały wyczyszczone)')),
      );
    }
  }
}