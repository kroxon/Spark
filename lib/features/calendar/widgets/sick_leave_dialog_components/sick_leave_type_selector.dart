import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/sick_leave_models.dart';

class SickLeaveTypeSelector extends StatelessWidget {
  const SickLeaveTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final SickLeaveType selectedType;
  final ValueChanged<SickLeaveType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rodzaj zwolnienia',
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
                          Icon(Icons.medical_services, size: 16),
                          const SizedBox(width: 4),
                          const Text('80%'),
                        ],
                      ),
                    ),
                    selected: selectedType == SickLeaveType.eightyPercent,
                    onSelected: (selected) {
                      if (selected) {
                        onTypeChanged(SickLeaveType.eightyPercent);
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
                          Icon(Icons.local_hospital, size: 16),
                          const SizedBox(width: 4),
                          const Text('100%'),
                        ],
                      ),
                    ),
                    selected: selectedType == SickLeaveType.hundredPercent,
                    onSelected: (selected) {
                      if (selected) {
                        onTypeChanged(SickLeaveType.hundredPercent);
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