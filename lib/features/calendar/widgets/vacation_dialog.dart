import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/data/calendar_entry_repository.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'package:iskra/features/calendar/utils/shift_cycle_calculator.dart';
import 'vacation_dialog_components/vacation_form.dart';
import 'vacation_dialog_components/vacation_conflict_dialog.dart';
import 'vacation_dialog_components/vacation_dialog_models.dart';

class VacationDialog extends ConsumerStatefulWidget {
  const VacationDialog({super.key});

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (_) => const VacationDialog(),
    );
  }

  @override
  ConsumerState<VacationDialog> createState() => _VacationDialogState();
}

class _VacationDialogState extends ConsumerState<VacationDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  VacationType _vacationType = VacationType.regular;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.9).clamp(400.0, 600.0); // 90% ekranu, min 400, max 600

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Chip title that "sticks out" above the dialog
        Positioned(
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Chip(
              label: const Text('Dodaj urlop'),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 6,
              shadowColor: theme.shadowColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        // Main dialog without title
        Padding(
          padding: const EdgeInsets.only(top: 32), // Space for the chip
          child: AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            content: SingleChildScrollView(
              child: SizedBox(
                width: dialogWidth,
                child: _buildContent(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: _isLoading || !_canSave ? null : _saveVacation,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Zapisz'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null) {
      return const Center(
        child: Text('Użytkownik nie jest zalogowany'),
      );
    }

    final userProfile = ref.watch(
      userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
    );

    return userProfile.when(
      data: (profile) => VacationForm(
        userProfile: profile,
        onVacationTypeChanged: (type) => setState(() => _vacationType = type),
        onStartDateChanged: (date) {
          setState(() => _startDate = date);
        },
        onEndDateChanged: (date) {
          setState(() => _endDate = date);
        },
        onHoursCalculated: (hours) {
          // Hours are handled in VacationForm
        },
        calculatePotentialHours: (start, end, profile) => _calculatePotentialHoursForRange(start, end, profile),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Błąd ładowania profilu: $error'),
      ),
    );
  }

  bool get _canSave {
    return _startDate != null &&
           _endDate != null &&
           _startDate!.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  Future<List<ConflictDay>> _checkConflicts() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return [];

    final repository = ref.read(calendarEntryRepositoryProvider);
    final conflicts = <ConflictDay>[];

    final currentDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    for (var date = currentDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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

  Future<double> _calculatePotentialHoursForRange(DateTime? startDate, DateTime? endDate, UserProfile userProfile) async {
    if (startDate == null || endDate == null) {
      return 0;
    }

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      return 0;
    }

    final repository = ref.read(calendarEntryRepositoryProvider);
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

  Future<ConflictResolution> _showConflictDialog(List<ConflictDay> conflicts) async {
    return await VacationConflictDialog.show(context, conflicts: conflicts);
  }

  Future<void> _saveVacation() async {
    if (!_canSave) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        throw Exception('Użytkownik nie jest zalogowany');
      }

      // Check for conflicts first
      final conflicts = await _checkConflicts();
      if (conflicts.isNotEmpty) {
        final resolution = await _showConflictDialog(conflicts);
        if (resolution == ConflictResolution.cancel) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }

        // Handle different resolution types
        if (resolution == ConflictResolution.clearAndAddVacation) {
          await _clearExistingStatusesAndAddVacation(conflicts);
          if (mounted) {
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      final repository = ref.read(calendarEntryRepositoryProvider);
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      final shiftCalculator = ShiftCycleCalculator();

      // Get user profile for shift calculations
      final userProfile = await userProfileRepository.watchProfile(user.uid).first;
      if (userProfile == null) {
        throw Exception('Nie udało się pobrać profilu użytkownika');
      }

      // Calculate total vacation hours that will be consumed
      double totalConsumedHours = 0;
      final currentDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

      // First pass: check existing entries and calculate consumption
      for (var date = currentDate;
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
        final hasConflict = conflicts.any((conflict) =>
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
          date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
        final hasConflict = conflicts.any((conflict) =>
          conflict.date.year == date.year &&
          conflict.date.month == date.month &&
          conflict.date.day == date.day);
        if (hasConflict) {
          continue;
        }

        // Create vacation event with appropriate hours for this day
        final eventType = _vacationType == VacationType.regular
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
          final newStandardHours = _vacationType == VacationType.regular
              ? (currentProfile.standardVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
              : currentProfile.standardVacationHours;

          final newAdditionalHours = _vacationType == VacationType.additional
              ? (currentProfile.additionalVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
              : currentProfile.additionalVacationHours;

          await userProfileRepository.updateVacationHours(
            uid: user.uid,
            standardVacationHours: newStandardHours,
            additionalVacationHours: newAdditionalHours,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Urlop został dodany')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas zapisywania: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearExistingStatusesAndAddVacation(List<ConflictDay> conflicts) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw Exception('Użytkownik nie jest zalogowany');
    }

    final repository = ref.read(calendarEntryRepositoryProvider);
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    final shiftCalculator = ShiftCycleCalculator();

    // Get user profile for shift calculations
    final userProfile = await userProfileRepository.watchProfile(user.uid).first;
    if (userProfile == null) {
      throw Exception('Nie udało się pobrać profilu użytkownika');
    }

    // First, restore vacation hours from ALL existing vacation events in the range that will be cleared
    double hoursToRestoreStandard = 0;
    double hoursToRestoreAdditional = 0;
    final currentDate = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDate = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    // Check all days in the range for existing vacations
    for (var date = currentDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
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
      final eventType = _vacationType == VacationType.regular
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
        final newStandardHours = _vacationType == VacationType.regular
            ? (currentProfile.standardVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.standardVacationHours;

        final newAdditionalHours = _vacationType == VacationType.additional
            ? (currentProfile.additionalVacationHours - totalConsumedHours).clamp(0.0, double.infinity)
            : currentProfile.additionalVacationHours;

        await userProfileRepository.updateVacationHours(
          uid: user.uid,
          standardVacationHours: newStandardHours,
          additionalVacationHours: newAdditionalHours,
        );
      }
    } else {
      // No hours consumed (no scheduled service in range)
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Urlop został dodany (istniejące statusy zostały wyczyszczone)')),
      );
    }
  }
}