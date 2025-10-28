import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/nav_destinations.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/core/navigation/widgets/app_scaffold_drawer.dart';

/// Główny shell aplikacji łączący dolną nawigację i menu boczne.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _lastPrimaryIndex = 0;

  void _navigateToSection(AppSection section) {
    final targetIndex = section.branchIndex;
    if (targetIndex == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(targetIndex, initialLocation: true);
    } else {
      widget.navigationShell.goBranch(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final currentSection = AppSections.byBranchIndex(currentIndex);

    if (currentSection.isPrimary) {
      _lastPrimaryIndex = AppSections.primary.indexOf(currentSection);
    }

    // final theme = Theme.of(context);
    // final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentSection.label),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profil użytkownika',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.pushNamed(AppRouteName.profile),
          ),
        ],
      ),
      drawer: AppScaffoldDrawer(
        selectedSection: currentSection,
        onDestinationSelected: (section) {
          Navigator.of(context).pop();
          _navigateToSection(section);
        },
      ),
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _lastPrimaryIndex,
        onDestinationSelected: (index) => _navigateToSection(AppSections.primary[index]),
        destinations: [
          for (final section in AppSections.primary)
            NavigationDestination(
              icon: Icon(section.icon),
              label: section.label,
            ),
        ],
      ),
    );
  }
}
