import 'package:flutter/material.dart';

class ThemeModeSwitchCard extends StatelessWidget {
  const ThemeModeSwitchCard({
    super.key,
    required this.isDarkMode,
    required this.isUpdating,
    required this.onChanged,
  });

  final bool isDarkMode;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
        onChanged: isUpdating ? null : onChanged,
      ),
    );
  }
}
