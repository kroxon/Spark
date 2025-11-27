import 'package:flutter/material.dart';

enum AppSectionType { primary, drawer }

/// Declarative description of every top-level section in the application shell.
class AppSection {
  const AppSection({
    required this.name,
    required this.path,
    required this.label,
    required this.icon,
    required this.type,
    required this.branchIndex,
  });

  final String name;
  final String path;
  final String label;
  final IconData icon;
  final AppSectionType type;
  final int branchIndex;

  bool get isPrimary => type == AppSectionType.primary;
}

class AppSections {
  const AppSections._();

  static const schedule = AppSection(
    name: 'schedule',
    path: '/schedule',
    label: 'Grafik',
    icon: Icons.calendar_month_outlined,
    type: AppSectionType.primary,
    branchIndex: 0,
  );

  static const statistics = AppSection(
    name: 'statistics',
    path: '/statistics',
    label: 'Statystyki',
    icon: Icons.insert_chart_outlined,
    type: AppSectionType.primary,
    branchIndex: 1,
  );

  static const extras = AppSection(
    name: 'extras',
    path: '/extras',
    label: 'Dodatki',
    icon: Icons.extension_outlined,
    type: AppSectionType.primary,
    branchIndex: 2,
  );

  static const settings = AppSection(
    name: 'settings',
    path: '/settings',
    label: 'Ustawienia',
    icon: Icons.settings_outlined,
    type: AppSectionType.drawer,
    branchIndex: 3,
  );

  static const reports = AppSection(
    name: 'reports',
    path: '/reports',
    label: 'Raporty PDF',
    icon: Icons.picture_as_pdf_outlined,
    type: AppSectionType.drawer,
    branchIndex: 4,
  );

  static const subscription = AppSection(
    name: 'subscription',
    path: '/subscription',
    label: 'Subskrypcja',
    icon: Icons.star_outline,
    type: AppSectionType.drawer,
    branchIndex: 5,
  );

  static const help = AppSection(
    name: 'help',
    path: '/help',
    label: 'Pomoc i wsparcie',
    icon: Icons.help_center_outlined,
    type: AppSectionType.drawer,
    branchIndex: 6,
  );

  static const all = <AppSection>[
    schedule,
    statistics,
    extras,
    settings,
    reports,
    subscription,
    help,
  ];

  static const primary = <AppSection>[
    schedule,
    statistics,
    extras,
  ];

  static const drawer = <AppSection>[
    settings,
    reports,
    subscription,
    help,
  ];

  static AppSection byBranchIndex(int index) =>
      all.firstWhere((section) => section.branchIndex == index, orElse: () => schedule);

  static AppSection? byPath(String path) {
    for (final section in all) {
      if (section.path == path) {
        return section;
      }
    }
    return null;
  }
}
