import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/calendar_entry.dart';
import 'vacation_dialog_helpers.dart';

class ConflictDay {
  const ConflictDay(this.date, this.events);

  final DateTime date;
  final List<DayEvent> events;

  String get formattedDate => '${date.day}.${date.month}.${date.year}';
}

class VacationConflictDialog extends StatelessWidget {
  const VacationConflictDialog({
    super.key,
    required this.conflicts,
    required this.onDismiss,
  });

  final List<ConflictDay> conflicts;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Nie można dodać urlopu'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Następujące dni z wybranego zakresu mają już przypisane statusy. '
                'Aby dodać urlop do tych dni, należy najpierw usunąć istniejące wpisy:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...conflicts.map((conflict) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.formattedDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...conflict.events.map((event) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              getEventIcon(event.type),
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${getEventTypeDisplayName(event.type)}: ${event.hours}h',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Urlop nie może zostać dodany do dni z istniejącymi wpisami. '
                        'Przejdź do kalendarza i usuń statusy z powyższych dni.',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: onDismiss,
          child: const Text('Rozumiem'),
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required List<ConflictDay> conflicts,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VacationConflictDialog(
        conflicts: conflicts,
        onDismiss: () => Navigator.of(context).pop(false),
      ),
    ).then((value) => value ?? false);
  }
}