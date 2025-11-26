import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:iskra/core/theme/app_bottom_nav_theme.dart';
import 'package:iskra/core/navigation/nav_destinations.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/core/navigation/widgets/app_scaffold_drawer.dart';

final currentNavIndexProvider = NotifierProvider<CurrentNavIndexNotifier, int>(CurrentNavIndexNotifier.new);

class CurrentNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

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

  void _navigateToSection(BuildContext context, AppSection section) {
    if (section.isPrimary) {
      final targetIndex = section.branchIndex;
      if (targetIndex == widget.navigationShell.currentIndex) {
        widget.navigationShell.goBranch(targetIndex, initialLocation: true);
      } else {
        widget.navigationShell.goBranch(targetIndex);
      }
    } else {
      // Drawer sections navigate by path (may live outside the shell). Use push to preserve back stack.
      context.push(section.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    // Update the provider with the current index
    // We use addPostFrameCallback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentNavIndexProvider) != currentIndex) {
        ref.read(currentNavIndexProvider.notifier).setIndex(currentIndex);
      }
    });

    final currentSection = AppSections.byBranchIndex(currentIndex);

    if (currentSection.isPrimary) {
      _lastPrimaryIndex = AppSections.primary.indexOf(currentSection);
    }

    // Control visibility of chrome elements per section
    final hideAppBar = currentSection == AppSections.settings || currentSection == AppSections.statistics;
    final hideBottomNav = currentSection == AppSections.settings;

    return WillPopScope(
      onWillPop: () async {
        // When in a drawer section (like Settings), go back to the last primary tab on back press
        final current = currentSection;
        if (!current.isPrimary) {
          _navigateToSection(context, AppSections.primary[_lastPrimaryIndex]);
          return false; // prevent default pop
        }
        return true; // allow default behavior
      },
      child: Scaffold(
        appBar: hideAppBar
            ? null
            : AppBar(
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
            _navigateToSection(context, section);
          },
        ),
        body: widget.navigationShell,
        bottomNavigationBar: hideBottomNav
            ? null
            : SafeArea(
                top: false,
                child: Builder(
                  builder: (context) {
                    final navTheme = Theme.of(context).extension<BottomNavColors>();
                    final background = navTheme?.background ?? Theme.of(context).colorScheme.surface;
                    final tabBg = navTheme?.tabBackground ?? Theme.of(context).colorScheme.secondaryContainer;
                    final active = navTheme?.activeColor ?? Theme.of(context).colorScheme.onSecondaryContainer;
                    final inactive = navTheme?.inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
                    final elevation = navTheme?.elevation ?? 3.0;
                    final containerRadius = navTheme?.containerRadius ?? 16.0;
                    final tabRadius = navTheme?.tabRadius ?? 12.0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Material(
                        elevation: elevation,
                        borderRadius: BorderRadius.circular(containerRadius),
                        clipBehavior: Clip.antiAlias,
                        color: background,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: GNav(
                            selectedIndex: _lastPrimaryIndex,
                            gap: 6,
                            onTabChange: (index) => _navigateToSection(context, AppSections.primary[index]),
                            color: inactive,
                            activeColor: active,
                            tabBackgroundColor: tabBg,
                            tabBorderRadius: tabRadius,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            tabs: [
                              for (final section in AppSections.primary)
                                GButton(
                                  icon: section.icon,
                                  text: section.label,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
