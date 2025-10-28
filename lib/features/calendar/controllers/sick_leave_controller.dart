import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/models/sick_leave_models.dart';
import 'package:iskra/features/calendar/widgets/sick_leave_dialog_components/sick_leave_conflict_dialog.dart';

class SickLeaveController {
  final WidgetRef _ref;
  final BuildContext _context;
  bool _isLoading = false;

  SickLeaveController(this._ref, this._context);

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

  Future<double> calculateSickLeaveHours({
    required DateTime startDate,
    required DateTime endDate,
    required SickLeaveType sickLeaveType,
  }) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return 0;

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final percentage = sickLeaveType == SickLeaveType.eightyPercent ? 0.8 : 1.0;

    double totalHours = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      // Check if user has scheduled hours for this day
      final existingEntry = await repository.getEntryForDay(user.uid, date);
      final scheduledHours = existingEntry?.scheduledHours ?? 8.0; // Default to 8 hours if not scheduled

      totalHours += scheduledHours * percentage;
    }

    return totalHours;
  }

  Future<int> calculateSickLeaveDays(DateTime startDate, DateTime endDate) async {
    int totalDays = 0;
    final currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      totalDays++;
    }

    return totalDays;
  }

  Future<ConflictResolution> showConflictDialog(List<ConflictDay> conflicts) async {
    return await SickLeaveConflictDialog.show(_context, conflicts: conflicts);
  }

  Future<void> saveSickLeave({
    required DateTime startDate,
    required DateTime endDate,
    required SickLeaveType sickLeaveType,
  }) async {
    _isLoading = true;

    try {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      final conflicts = await checkConflicts(startDate, endDate);

      // Handle different resolution types
      if (conflicts.isNotEmpty) {
        final resolution = await showConflictDialog(conflicts);
        if (resolution == ConflictResolution.cancel) {
          _isLoading = false;
          return;
        }

        if (resolution == ConflictResolution.clearAndAddSickLeave) {
          await _clearExistingStatusesAndAddSickLeave(startDate, endDate, sickLeaveType, conflicts);
          _isLoading = false;
          return;
        }
      }

      await _saveSickLeaveDirect(startDate, endDate, sickLeaveType, conflicts);

      if (_context.mounted) {
        Navigator.of(_context).pop();
        ScaffoldMessenger.of(_context).showSnackBar(
          const SnackBar(content: Text('Zwolnienie lekarskie zostało dodane')),
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

  Future<void> _saveSickLeaveDirect(DateTime startDate, DateTime endDate, SickLeaveType sickLeaveType, List<ConflictDay> conflicts) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final repository = _ref.read(calendarEntryRepositoryProvider);

    // Calculate hours per day
    final totalHours = await calculateSickLeaveHours(
      startDate: startDate,
      endDate: endDate,
      sickLeaveType: sickLeaveType,
    );
    final totalDays = await calculateSickLeaveDays(startDate, endDate);
    final hoursPerDay = totalDays > 0 ? totalHours / totalDays : 0;

    // Create sick leave event
    final eventType = sickLeaveType == SickLeaveType.eightyPercent
        ? EventType.sickLeave80
        : EventType.sickLeave100;

    final sickLeaveEvent = DayEvent(
      type: eventType,
      hours: hoursPerDay.toDouble(),
    );

    // Save sick leave for each day in the range
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
      if (hasConflict) {
        continue;
      }

      await repository.saveDayDetails(
        userId: user.uid,
        day: date,
        events: [sickLeaveEvent],
        incidents: const [],
        note: '',
        scheduledHours: null, // Don't change scheduled hours
      );
    }
  }

  Future<void> _clearExistingStatusesAndAddSickLeave(DateTime startDate, DateTime endDate, SickLeaveType sickLeaveType, List<ConflictDay> conflicts) async {
    final user = _ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final repository = _ref.read(calendarEntryRepositoryProvider);
    final userProfileRepository = _ref.read(userProfileRepositoryProvider);

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

    // Calculate hours per day
    final totalHours = await calculateSickLeaveHours(
      startDate: startDate,
      endDate: endDate,
      sickLeaveType: sickLeaveType,
    );
    final totalDays = await calculateSickLeaveDays(startDate, endDate);
    final hoursPerDay = totalDays > 0 ? totalHours / totalDays : 0;

    // Create sick leave event
    final eventType = sickLeaveType == SickLeaveType.eightyPercent
        ? EventType.sickLeave80
        : EventType.sickLeave100;

    final sickLeaveEvent = DayEvent(
      type: eventType,
      hours: hoursPerDay.toDouble(),
    );

    // Save sick leave for each day in the range
    for (var date = currentDate;
        date.isBefore(endDateTime) || date.isAtSameMomentAs(endDateTime);
        date = date.add(const Duration(days: 1))) {

      await repository.saveDayDetails(
        userId: user.uid,
        day: date,
        events: [sickLeaveEvent],
        incidents: const [],
        note: '',
        scheduledHours: null, // Don't change scheduled hours
      );
    }

    if (_context.mounted) {
      Navigator.of(_context).pop();
      ScaffoldMessenger.of(_context).showSnackBar(
        const SnackBar(content: Text('Zwolnienie lekarskie zostało dodane (istniejące statusy zostały wyczyszczone)')),
      );
    }
  }
}