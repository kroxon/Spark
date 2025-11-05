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
          // Inline section: Historia przydziału do zmian
          const ShiftHistorySection(),
        ],
      ),
    );
  }
}
 
