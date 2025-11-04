import 'package:flutter/material.dart';

class BalancesSettingsPage extends StatelessWidget {
  const BalancesSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Salda i wskaźniki')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Zarządzaj saldami urlopów i nadgodzin. Ustawienia te pozwalają na kontrolę i korekty.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _SettingInfoCard(
            icon: Icons.beach_access_outlined,
            title: 'Zarządzanie saldem urlopów',
            description:
                'Definiuj początkowe salda, korekty i zasady naliczania. Moduł w przygotowaniu, wkrótce dostępny.',
          ),
          const SizedBox(height: 16),
          _SettingInfoCard(
            icon: Icons.timelapse_outlined,
            title: 'Zarządzanie saldem nadgodzin',
            description:
                'Przeglądaj i koryguj nadgodziny, ustawiaj progi i reguły. Moduł w przygotowaniu, wkrótce dostępny.',
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
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(icon, color: theme.colorScheme.onTertiaryContainer),
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
