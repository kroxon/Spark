import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';

class ExtrasPage extends StatelessWidget {
  const ExtrasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dodatki',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Dodatkowe funkcje i narzędzia wspierające Twoją pracę.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          
          // Game 2048 Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pushNamed(AppRouteName.game2048),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2048: PSP Edition',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Połącz dystynkcje i awansuj od strażaka do generała!',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // KPP Learning Module Card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.pushNamed(AppRouteName.kppMenu),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F), // Red color for medical/emergency
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nauka KPP',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Baza pytań, fiszki i tryb nauki do egzaminu KPP.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Więcej dodatków wkrótce',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tutaj znajdziesz dodatkowe moduły i rozszerzenia aplikacji, które pomogą Ci w codziennych zadaniach.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
