import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analiza i Statystyki',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Wskaźniki skuteczności działań, czasy reakcji oraz trendy.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Card(
              elevation: 1,
              child: Center(
                child: Text(
                  'Panel statystyk w przygotowaniu',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
