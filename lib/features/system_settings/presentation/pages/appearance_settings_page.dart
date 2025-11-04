import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/theme/theme_mode_controller.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/application/calendar_indicator_settings_controller.dart';
import 'package:iskra/features/system_settings/presentation/widgets/overtime_indicator_settings_card.dart';
import 'package:iskra/features/system_settings/presentation/widgets/theme_mode_switch_card.dart';

class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends ConsumerState<AppearanceSettingsPage> {
  bool _isUpdatingTheme = false;
  bool _isSavingOvertimeThreshold = false;
  double? _overtimeThresholdDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final currentUser = ref.watch(firebaseAuthProvider).currentUser;
    final AsyncValue<UserProfile>? profileAsync = currentUser == null
        ? null
        : ref.watch(
            userProfileProvider(
              UserProfileRequest(
                uid: currentUser.uid,
                email: currentUser.email,
              ),
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Wygląd i personalizacja')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dostosuj wygląd aplikacji i sposób prezentacji danych.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ThemeModeSwitchCard(
              isDarkMode: isDarkMode,
              isUpdating: _isUpdatingTheme,
              onChanged: (isEnabled) => _onThemeChanged(context, isEnabled),
            ),
            const SizedBox(height: 24),
            _ShiftColorsCard(onOpenConfigurator: () => _showShiftColorsDialog(context)),
            if (profileAsync != null) ...[
              const SizedBox(height: 24),
              profileAsync.when(
                data: (profile) {
                  final storedThreshold = profile.overtimeIndicatorThresholdHours;

                  if (_overtimeThresholdDraft != null &&
                      (_overtimeThresholdDraft! - storedThreshold).abs() < 0.5) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _overtimeThresholdDraft = null);
                      }
                    });
                  }

                  return OvertimeIndicatorSettingsCard(
                    currentThreshold: storedThreshold,
                    draftThreshold: _overtimeThresholdDraft,
                    isSaving: _isSavingOvertimeThreshold,
                    onDraftChanged: (value) {
                      setState(() => _overtimeThresholdDraft = value);
                    },
                    onSavePressed: (hours) => _onSaveOvertimeThreshold(context, hours),
                  );
                },
                loading: () => const Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nie udało się załadować ustawień wskaźnika.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onThemeChanged(BuildContext context, bool isEnabled) async {
    if (_isUpdatingTheme) return;

    setState(() => _isUpdatingTheme = true);
    try {
      final controller = ref.read(themePreferencesControllerProvider);
      await controller.setThemeMode(isEnabled ? ThemeMode.dark : ThemeMode.light);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać motywu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingTheme = false);
    }
  }

  Future<void> _onSaveOvertimeThreshold(BuildContext context, double hours) async {
    if (_isSavingOvertimeThreshold) return;

    setState(() => _isSavingOvertimeThreshold = true);
    try {
      final controller = ref.read(calendarIndicatorSettingsControllerProvider);
      await controller.setOvertimeIndicatorThreshold(hours);
      if (mounted) setState(() => _overtimeThresholdDraft = hours);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zapisano próg dla wskaźnika służby.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać progu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingOvertimeThreshold = false);
    }
  }

  void _showShiftColorsDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kolory zmian', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Konfigurator kolorów zmian jest w przygotowaniu. Wkrótce pozwoli spersonalizować barwy dla typów zmian.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zamknij'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShiftColorsCard extends StatelessWidget {
  const _ShiftColorsCard({required this.onOpenConfigurator});
  final VoidCallback onOpenConfigurator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text('Kolory zmian', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Personalizuj kolory dla różnych typów zmian w kalendarzu.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onOpenConfigurator,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Otwórz konfigurator'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
