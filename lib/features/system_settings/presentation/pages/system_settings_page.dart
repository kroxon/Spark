import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
// Removed card-based layout; using light list-style rows instead.

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          _SettingsRow(
            title: 'Wygląd i personalizacja',
            subtitle: 'Motyw aplikacji, kolory zmian, indykator nadgodzin',
            onTap: () => context.pushNamed(AppRouteName.settingsAppearance),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _SettingsRow(
            title: 'Mój harmonogram',
            subtitle: 'Historia przydziału do zmian, niestandardowe nieobecności',
            onTap: () => context.pushNamed(AppRouteName.settingsSchedule),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _SettingsRow(
            title: 'Salda i wskaźniki',
            subtitle: 'Zarządzanie saldem urlopów',
            onTap: () => context.pushNamed(AppRouteName.settingsBalances),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
