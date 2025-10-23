import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/theme/theme_mode_controller.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/auth/domain/models/user_profile.dart';
import 'package:iskra/features/calendar/application/calendar_indicator_settings_controller.dart';
import 'package:iskra/features/system_settings/presentation/widgets/overtime_indicator_settings_card.dart';
import 'package:iskra/features/system_settings/presentation/widgets/theme_mode_switch_card.dart';

class SystemSettingsPage extends ConsumerStatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  ConsumerState<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<SystemSettingsPage> {
  bool _isUpdatingTheme = false;
  bool _isSavingOvertimeThreshold = false;
  double? _overtimeThresholdDraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isUpdating = _isUpdatingTheme;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System i Integracje',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Konfiguruj jednostkę, integracje zewnętrzne i uprawnienia systemowe.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ThemeModeSwitchCard(
            isDarkMode: isDarkMode,
            isUpdating: isUpdating,
            onChanged: (isEnabled) => _onThemeChanged(context, isEnabled),
          ),
          if (profileAsync != null) ...[
            const SizedBox(height: 24),
            profileAsync.when(
              data: (profile) {
                final storedThreshold =
                    profile.overtimeIndicatorThresholdHours;

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
                  onSavePressed: (hours) =>
                      _onSaveOvertimeThreshold(context, hours),
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
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel administracyjny w przygotowaniu',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Docelowo zdefiniujesz tutaj strukturę jednostki, integracje z systemami alarmowania oraz automatyzacje.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onThemeChanged(BuildContext context, bool isEnabled) async {
    if (_isUpdatingTheme) {
      return;
    }

    setState(() => _isUpdatingTheme = true);
    try {
      final controller = ref.read(themePreferencesControllerProvider);
      await controller.setThemeMode(
        isEnabled ? ThemeMode.dark : ThemeMode.light,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać motywu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTheme = false);
      }
    }
  }

  Future<void> _onSaveOvertimeThreshold(
    BuildContext context,
    double hours,
  ) async {
    if (_isSavingOvertimeThreshold) {
      return;
    }

    setState(() => _isSavingOvertimeThreshold = true);
    try {
      final controller = ref.read(calendarIndicatorSettingsControllerProvider);
      await controller.setOvertimeIndicatorThreshold(hours);
      if (mounted) {
        setState(() => _overtimeThresholdDraft = hours);
      }
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zapisano próg dla wskaźnika służby.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać progu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingOvertimeThreshold = false);
      }
    }
  }
}
