import 'package:flutter/material.dart';

class VacationDialog extends StatelessWidget {
  const VacationDialog({super.key});

  static Future<void> show({required BuildContext context}) {
    return showDialog(
      context: context,
      builder: (_) => const VacationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        'Dodaj urlop',
        style: theme.textTheme.headlineSmall,
      ),
      content: const SizedBox(
        width: 300,
        child: Text('Dialog zostanie opracowany później.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij'),
        ),
        FilledButton(
          onPressed: () {
            // TODO: Implement save logic
            Navigator.of(context).pop();
          },
          child: const Text('Zapisz'),
        ),
      ],
    );
  }
}