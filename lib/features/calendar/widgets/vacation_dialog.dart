import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/controllers/vacation_controller.dart';
import 'package:iskra/features/calendar/models/vacation_models.dart';
import 'vacation_dialog_components/vacation_form.dart';

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
  late VacationController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = VacationController(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.9).clamp(400.0, 600.0); // 90% ekranu, min 400, max 600

    return WillPopScope(
      onWillPop: () async => !(_isProcessing || _controller.isLoading),
      child: Stack(
      alignment: Alignment.topCenter,
      children: [
        // Chip title that 'sticks out' above the dialog
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
                // While processing, block all interaction inside the dialog.
                child: AbsorbPointer(
                  absorbing: _isProcessing || _controller.isLoading,
                  child: Opacity(
                    opacity: (_isProcessing || _controller.isLoading) ? 0.6 : 1.0,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: (_controller.isLoading || _isProcessing) || !_canSave ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: (_controller.isLoading || _isProcessing) || !_canSave ? null : _saveVacation,
                child: (_controller.isLoading || _isProcessing)
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
      ),
    );
  }

  Widget _buildContent() {
    final user = ref.watch(firebaseAuthProvider).currentUser;

    if (user == null) {
      return const Center(
        child: Text('U�ytkownik nie jest zalogowany'),
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
        calculatePotentialHours: (start, end, profile) => _controller.calculatePotentialHoursForRange(start, end, profile),
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

  Future<void> _saveVacation() async {
    if (!_canSave) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Użytkownik nie jest zalogowany')));
      }
      return;
    }

    // Load latest profile
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    final userProfile = await userProfileRepository.watchProfile(user.uid).first;
    if (userProfile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie udało się pobrać profilu użytkownika')));
      }
      return;
    }

    // First check required hours for the full selected range (before resolving conflicts)
    // We want to verify availability of balances first and only then present conflict resolution.
    final requiredHours = await _controller.calculatePotentialHoursForRange(
      _startDate!,
      _endDate!,
      userProfile,
    );

  final primaryAvailable = _vacationType == VacationType.regular
    ? userProfile.standardVacationHours
    : userProfile.additionalVacationHours;
  final secondaryAvailable = _vacationType == VacationType.regular
    ? userProfile.additionalVacationHours
    : userProfile.standardVacationHours;

  // Account for hours that would be restored if existing vacation events in
  // the selected range are cleared (they return to the user's balances).
  final restored = await _controller.computeRestoredHoursForRange(_startDate!, _endDate!);
  final restoredPrimary = _vacationType == VacationType.regular ? restored['standard'] ?? 0.0 : restored['additional'] ?? 0.0;
  final restoredSecondary = _vacationType == VacationType.regular ? restored['additional'] ?? 0.0 : restored['standard'] ?? 0.0;

  final effectivePrimaryAvailable = primaryAvailable + restoredPrimary;
  final effectiveSecondaryAvailable = secondaryAvailable + restoredSecondary;

    // Detect if secondary hours are absent because they are already assigned in the schedule.
    // Use the effective secondary availability (including restored hours). If effective
    // secondary is still zero, we may have occupied secondary hours that prevent top-up.
    if (effectivePrimaryAvailable < requiredHours && effectiveSecondaryAvailable <= 0.0) {
      final occupiedDays = await _controller.findDaysWithSecondaryVacationEvents(_startDate!, _endDate!, _vacationType);
      if (occupiedDays.isNotEmpty) {
  if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Przypisane godziny w wybranym zakresie'),
              content: const Text('W wybranym zakresie dat znajdują się już przypisane godziny urlopu. Aby przypisać nowy urlop w tym zakresie, usuń najpierw ręcznie istniejące wpisy w grafiku, a następnie ponownie wybierz zakres i zapisz urlop.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
              ],
            ),
          );
        }
        return;
      }
    }

    if (effectivePrimaryAvailable >= requiredHours) {
      // primary (after restoring any overwritten events) covers all -> compute conflicts and proceed
      setState(() => _isProcessing = true);
      try {
        final conflicts = await _controller.checkConflicts(_startDate!, _endDate!);
        await _controller.saveVacation(
          startDate: _startDate!,
          endDate: _endDate!,
          vacationType: _vacationType,
          conflicts: conflicts,
          secondaryToUse: 0.0,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urlop został dodany')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wystąpił błąd podczas zapisu.')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
      return;
    }

    // Not enough primary hours
  if (effectivePrimaryAvailable + effectiveSecondaryAvailable < requiredHours) {
      // Combined insufficient -> show informative dialog and block save
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Niewystarczające godziny'),
            content: const Text('Brakuje dostępnych godzin urlopu dla wybranego zakresu. Uzupełnij stan urlopów lub wybierz krótszy zakres.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

  // Combined suffices -> propose to top up from secondary
  // Determine how much would be consumed from primary vs secondary, taking into
  // account restored hours that increase effective availability.
  final primaryWillBe = effectivePrimaryAvailable >= requiredHours ? requiredHours : effectivePrimaryAvailable;
  final secondaryWillBe = (requiredHours - primaryWillBe).clamp(0.0, double.infinity);

    // Prepare human-friendly labels depending on selected vacation type
  // Human-friendly labels: use fixed phrases to match existing terminology
  final primaryLabel = _vacationType == VacationType.regular
    ? 'Urlop wypoczynkowy '
    : 'Urlop dodatkowy';

  final secondaryLabel = _vacationType == VacationType.regular
    ? 'Urlop dodatkowy'
    : 'Urlop wypoczynkowy ';

    if (context.mounted) {
      final useSecond = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Uzupełnienie urlopu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wymagana liczba godzin: ${requiredHours.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Text('Dostępne — $primaryLabel: ${effectivePrimaryAvailable.toStringAsFixed(0)} godz.'),
              Text('Dostępne — $secondaryLabel: ${effectiveSecondaryAvailable.toStringAsFixed(0)} godz.'),
              const SizedBox(height: 8),
              const Text('Proponowane rozliczenie godzin:'),
              const SizedBox(height: 4),
              Text('- Z głównego stanu: ${primaryWillBe.toStringAsFixed(0)} godz.'),
              Text('- Z drugiego stanu: ${secondaryWillBe.toStringAsFixed(0)} godz.'),
              const SizedBox(height: 8),
              const Text('Czy zatwierdzasz użycie drugiego stanu, aby uzupełnić brak?'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Anuluj')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Tak, zatwierdź')),
          ],
        ),
      );

      if (useSecond == true) {
        debugPrint('[VacationDialog] User confirmed using secondary balance: primaryWillBe=$primaryWillBe, secondaryWillBe=$secondaryWillBe');
        // Show spinner on main dialog's Save button and perform save; close dialog after success.
        setState(() => _isProcessing = true);
        try {
          final conflicts = await _controller.checkConflicts(_startDate!, _endDate!);
          await _controller.saveVacation(
            startDate: _startDate!,
            endDate: _endDate!,
            vacationType: _vacationType,
            conflicts: conflicts,
            secondaryToUse: secondaryWillBe,
          );
          // Close the VacationDialog after successful save and show success
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urlop został dodany')));
            Navigator.of(context).pop();
          }
        } catch (e) {
          debugPrint('[VacationDialog] Error while saving vacation: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wystąpił błąd podczas zapisu. Spróbuj ponownie.')));
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      } else {
        debugPrint('[VacationDialog] User cancelled secondary usage');
      }
    }
  }
}
