import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';

class BalancesSettingsPage extends ConsumerWidget {
  const BalancesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Salda i wskaźniki')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          if (user == null)
            const _SettingsSection(
              title: 'Zarządzanie saldem urlopów',
              description: 'Zaloguj się, aby edytować salda urlopów.',
            )
          else
            _VacationBalanceSection(uid: user.uid, email: user.email),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationBalanceSection extends ConsumerWidget {
  const _VacationBalanceSection({required this.uid, required this.email});
  final String uid;
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider(UserProfileRequest(uid: uid, email: email)));

    return profileAsync.when(
      data: (profile) {
        final hoursStd = profile.standardVacationHours.round();
        final hoursAdd = profile.additionalVacationHours.round();
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openEditor(context, ref, profile),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zarządzanie saldem urlopów', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Podstawowy', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('${hoursStd} h', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dodatkowy', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('${hoursAdd} h', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Błąd wczytywania profilu: $e', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, UserProfile profile) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _VacationBalanceDialog(profile: profile),
    );
  }
}

class _VacationBalanceDialog extends ConsumerStatefulWidget {
  const _VacationBalanceDialog({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_VacationBalanceDialog> createState() => _VacationBalanceDialogState();
}

class _VacationBalanceDialogState extends ConsumerState<_VacationBalanceDialog> {
  late TextEditingController _stdCtrl;
  late TextEditingController _addCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stdCtrl = TextEditingController(text: widget.profile.standardVacationHours.round().toString());
    _addCtrl = TextEditingController(text: widget.profile.additionalVacationHours.round().toString());
  }

  @override
  void dispose() {
    _stdCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edytuj salda urlopów'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _numberField(
                context,
                label: 'Urlop podstawowy (h)',
                controller: _stdCtrl,
                unit: 'h',
              ),
              const SizedBox(height: 8),
              _numberField(
                context,
                label: 'Urlop dodatkowy (h)',
                controller: _addCtrl,
                unit: 'h',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Anuluj')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Zapisz'),
        ),
      ],
    );
  }

  Widget _numberField(BuildContext context, {required String label, required TextEditingController controller, required String unit}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            suffixText: unit,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
  int parseInt(TextEditingController c) => int.tryParse(c.text) ?? 0;
  double std = parseInt(_stdCtrl).toDouble();
  double add = parseInt(_addCtrl).toDouble();
      std = std.clamp(0.0, 10000.0);
      add = add.clamp(0.0, 10000.0);
      final repo = ref.read(userProfileRepositoryProvider);
      await repo.updateVacationHours(
        uid: widget.profile.uid,
        standardVacationHours: std,
        additionalVacationHours: add,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nie udało się zapisać: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
