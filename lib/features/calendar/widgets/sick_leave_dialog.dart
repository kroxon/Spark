import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/controllers/sick_leave_controller.dart';
import 'package:iskra/features/calendar/models/sick_leave_models.dart';
import 'sick_leave_dialog_components/sick_leave_form.dart';

class SickLeaveDialog extends ConsumerStatefulWidget {
  const SickLeaveDialog({super.key});

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (_) => const SickLeaveDialog(),
    );
  }

  @override
  ConsumerState<SickLeaveDialog> createState() => _SickLeaveDialogState();
}

class _SickLeaveDialogState extends ConsumerState<SickLeaveDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  SickLeaveType _sickLeaveType = SickLeaveType.eightyPercent;
  late SickLeaveController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SickLeaveController(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.9).clamp(400.0, 600.0);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: Chip(
              label: const Text('Dodaj zwolnienie lekarskie'),
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
        Padding(
          padding: const EdgeInsets.only(top: 32),
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
                onPressed: _controller.isLoading || !_canSave ? null : _saveSickLeave,
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
      data: (profile) => SickLeaveForm(
        userProfile: profile,
        controller: _controller,
        onSickLeaveTypeChanged: (type) => setState(() => _sickLeaveType = type),
        onStartDateChanged: (date) {
          setState(() => _startDate = date);
        },
        onEndDateChanged: (date) {
          setState(() => _endDate = date);
        },
        onHoursCalculated: (hours) {},
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

  Future<void> _saveSickLeave() async {
    if (!_canSave) return;

    await _controller.saveSickLeave(
      startDate: _startDate!,
      endDate: _endDate!,
      sickLeaveType: _sickLeaveType,
    );
  }
}
