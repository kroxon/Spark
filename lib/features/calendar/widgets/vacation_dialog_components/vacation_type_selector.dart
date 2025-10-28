import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/vacation_models.dart';

class VacationTypeSelector extends StatelessWidget {
  const VacationTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final VacationType selectedType;
  final ValueChanged<VacationType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rodzaj urlopu',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final chipWidth = (availableWidth - 8) / 2; // Odejmujemy spacing, dzielimy na pół

            return Row(
              children: [
                SizedBox(
                  width: chipWidth,
                  child: ChoiceChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.beach_access, size: 16),
                          const SizedBox(width: 4),
                          const Text('Wypoczynkowy'),
                        ],
                      ),
                    ),
                    selected: selectedType == VacationType.regular,
                    onSelected: (selected) {
                      if (selected) {
                        onTypeChanged(VacationType.regular);
                      }
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: chipWidth,
                  child: ChoiceChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.park_outlined, size: 16),
                          const SizedBox(width: 4),
                          const Text('Dodatkowy'),
                        ],
                      ),
                    ),
                    selected: selectedType == VacationType.additional,
                    onSelected: (selected) {
                      if (selected) {
                        onTypeChanged(VacationType.additional);
                      }
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}