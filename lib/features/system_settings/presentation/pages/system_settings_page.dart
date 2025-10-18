import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/core/theme/theme_mode_controller.dart';

class SystemSettingsPage extends ConsumerStatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  ConsumerState<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends ConsumerState<SystemSettingsPage> {
  bool _isUpdatingTheme = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final isUpdating = _isUpdatingTheme;

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
          Card(
            elevation: 1,
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              title: Text('Motyw ciemny', style: theme.textTheme.titleMedium),
              subtitle: Text(
                isUpdating
                    ? 'Zapisywanie preferencji...'
                    : 'Synchronizuj wygląd aplikacji między urządzeniami.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: isDarkMode,
              onChanged: isUpdating
                  ? null
                  : (isEnabled) => _onThemeChanged(context, isEnabled),
            ),
          ),
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
}
