import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/models/quick_status_validator.dart';

/// Dialog showing validation conflicts with suggestions
class ValidationConflictDialog extends StatelessWidget {
  const ValidationConflictDialog({
    super.key,
    required this.conflicts,
    required this.onDismiss,
  });

  final List<ValidationConflict> conflicts;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = conflicts.any((c) => c.severity == ValidationSeverity.error);
    final hasWarnings = conflicts.any((c) => c.severity == ValidationSeverity.warning);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            hasErrors ? Icons.error_outline : Icons.info_outline,
            color: hasErrors ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            hasErrors ? 'Błędy walidacji' : 'Ostrzeżenia',
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasErrors && hasWarnings) ...[
                _buildSection(
                  'Błędy (wymagają poprawy):',
                  conflicts.where((c) => c.severity == ValidationSeverity.error).toList(),
                  theme,
                  isError: true,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  'Ostrzeżenia:',
                  conflicts.where((c) => c.severity == ValidationSeverity.warning).toList(),
                  theme,
                  isError: false,
                ),
              ] else ...[
                _buildSection(
                  hasErrors ? 'Błędy:' : 'Ostrzeżenia:',
                  conflicts,
                  theme,
                  isError: hasErrors,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('Rozumiem'),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<ValidationConflict> sectionConflicts,
    ThemeData theme, {
    required bool isError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...sectionConflicts.map((conflict) => _buildConflict(conflict, theme, isError)),
      ],
    );
  }

  Widget _buildConflict(ValidationConflict conflict, ThemeData theme, bool isError) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError
              ? theme.colorScheme.error.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                size: 20,
                color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (conflict.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Sugestie:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...conflict.suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required List<ValidationConflict> conflicts,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ValidationConflictDialog(
        conflicts: conflicts,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }
}