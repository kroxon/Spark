import 'package:flutter/material.dart';

class ScheduleSettingsPage extends StatelessWidget {
  const ScheduleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mój harmonogram')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingInfoCard(
            icon: Icons.history_toggle_off_rounded,
            title: 'Historia przydziału do zmian',
            description:
                'Przeglądaj i analizuj historię przydziałów. Moduł w przygotowaniu, wkrótce dostępny.',
          ),
        ],
      ),
    );
  }
}

class _SettingInfoCard extends StatelessWidget {
  const _SettingInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

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
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(icon, color: theme.colorScheme.onSecondaryContainer),
                ),
                const SizedBox(width: 12),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
