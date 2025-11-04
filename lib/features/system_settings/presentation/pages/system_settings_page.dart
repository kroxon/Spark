import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/system_settings/presentation/widgets/settings_group_card.dart';

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          SettingsGroupCard(
            icon: Icons.color_lens_outlined,
            title: 'Wygląd i personalizacja',
            subtitle: 'Motyw aplikacji, kolory zmian, indykator nadgodzin',
            onTap: () => context.pushNamed(AppRouteName.settingsAppearance),
          ),
          const SizedBox(height: 12),
          SettingsGroupCard(
            icon: Icons.event_note_outlined,
            title: 'Mój harmonogram',
            subtitle: 'Historia przydziału do zmian, niestandardowe nieobecności',
            onTap: () => context.pushNamed(AppRouteName.settingsSchedule),
          ),
          const SizedBox(height: 12),
          SettingsGroupCard(
            icon: Icons.assessment_outlined,
            title: 'Salda i wskaźniki',
            subtitle: 'Zarządzanie saldem urlopów i nadgodzin',
            onTap: () => context.pushNamed(AppRouteName.settingsBalances),
          ),
        ],
      ),
    );
  }
}
