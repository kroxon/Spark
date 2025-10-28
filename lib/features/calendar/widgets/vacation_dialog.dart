import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
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

    return Stack(
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
                child: _buildContent(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _controller.isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: _controller.isLoading || !_canSave ? null : _saveVacation,
                child: _controller.isLoading
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

    final conflicts = await _controller.checkConflicts(_startDate!, _endDate!);

    await _controller.saveVacation(
      startDate: _startDate!,
      endDate: _endDate!,
      vacationType: _vacationType,
      conflicts: conflicts,
    );
  }
}
