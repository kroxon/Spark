import 'package:flutter/material.dart';
import 'package:iskra/core/navigation/nav_destinations.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Drawer wykorzystywany w głównym szkielecie aplikacji.
class AppScaffoldDrawer extends StatelessWidget {
  const AppScaffoldDrawer({
    required this.selectedSection,
    required this.onDestinationSelected,
    super.key,
  });

  final AppSection selectedSection;
  final ValueChanged<AppSection> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drawerSections = AppSections.drawer;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(gradient: AppColors.mainGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Iskra',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nawigacja pomocnicza',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Sekcje',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemBuilder: (context, index) {
                  final section = drawerSections[index];
                  final isSelected = section.branchIndex == selectedSection.branchIndex;

                  return ListTile(
                    leading: Icon(section.icon),
                    title: Text(section.label),
                    subtitle: Text(section.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                    onTap: () => onDestinationSelected(section),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: drawerSections.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Text(
                'Wersja 0.1.0',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
