import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/sick_leave_models.dart';
import '../vacation_dialog_components/vacation_dialog_helpers.dart';

class SickLeaveConflictDialog extends StatelessWidget {
  const SickLeaveConflictDialog({
    super.key,
    required this.conflicts,
    required this.onResolution,
  });

  final List<ConflictDay> conflicts;
  final ValueChanged<ConflictResolution> onResolution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Następujące dni z wybranego zakresu mają już przypisane statusy. '
                'Aby dodać zwolnienie lekarskie do tych dni, należy najpierw usunąć istniejące wpisy:',
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
                        'Zwolnienie lekarskie nie może zostać dodane do dni z istniejącymi wpisami. '
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
        TextButton(
          onPressed: () => onResolution(ConflictResolution.cancel),
          child: const Text('Anuluj'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => onResolution(ConflictResolution.clearAndAddSickLeave),
          child: const Text('Wyczyść i dodaj zwolnienie'),
        ),
      ],
    );
  }

  static Future<ConflictResolution> show(
    BuildContext context, {
    required List<ConflictDay> conflicts,
  }) {
    return showDialog<ConflictResolution>(
      context: context,
      builder: (context) => SickLeaveConflictDialog(
        conflicts: conflicts,
        onResolution: (resolution) => Navigator.of(context).pop(resolution),
      ),
    ).then((value) => value ?? ConflictResolution.cancel);
  }
}