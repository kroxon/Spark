import 'package:flutter/material.dart';
import 'package:iskra/features/system_settings/presentation/pages/shift_history_page.dart';

class ScheduleSettingsPage extends StatelessWidget {
  const ScheduleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mój harmonogram')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShiftHistoryPage()),
                  );
                },
                child: const _SettingInfoCard(
                  title: 'Historia przydziału do zmian',
                ),
              ),
        ],
      ),
    );
  }
}

class _SettingInfoCard extends StatelessWidget {
  const _SettingInfoCard({
    required this.title,
    // required this.description,
  });

  final String title;

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
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
