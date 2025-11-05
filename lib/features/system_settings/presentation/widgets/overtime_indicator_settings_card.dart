import 'package:flutter/material.dart';

class OvertimeIndicatorSettingsCard extends StatelessWidget {
  const OvertimeIndicatorSettingsCard({
    super.key,
    required this.currentThreshold,
    required this.draftThreshold,
    required this.isSaving,
    required this.onDraftChanged,
    required this.onSavePressed,
  });

  final double currentThreshold;
  final double? draftThreshold;
  final bool isSaving;
  final ValueChanged<double> onDraftChanged;
  final void Function(double hours) onSavePressed;

  static const double minHours = 0;
  static const double maxHours = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderValue =
        (draftThreshold ?? currentThreshold).clamp(minHours, maxHours);
    final roundedValue = sliderValue.roundToDouble();
    final hasChanges = draftThreshold != null &&
        roundedValue != currentThreshold.roundToDouble();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wskaźnik służby', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Kontroluj, przy ilu nadgodzinach pojawi się wskaźnik "na służbie".',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Próg nadgodzin', style: theme.textTheme.bodyMedium),
                Text('${roundedValue.round()} h',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            Slider(
              min: minHours,
              max: maxHours,
              divisions: (maxHours - minHours).toInt(),
              value: roundedValue,
              label: '${roundedValue.round()} h',
              onChanged: isSaving
                  ? null
                  : (value) => onDraftChanged(value.roundToDouble()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: (!hasChanges || isSaving)
                      ? null
                      : () => onSavePressed(roundedValue),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Zapisz próg'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
