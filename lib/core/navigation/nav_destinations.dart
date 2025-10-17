import 'package:flutter/material.dart';

enum AppSectionType { primary, drawer }

/// Declarative description of every top-level section in the application shell.
class AppSection {
  const AppSection({
    required this.name,
    required this.path,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.branchIndex,
  });

  final String name;
  final String path;
  final String label;
  final String subtitle;
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
    subtitle: 'Steruj grafikiem dyżurów i wpisami kalendarza',
    icon: Icons.calendar_month_outlined,
    type: AppSectionType.primary,
    branchIndex: 0,
  );

  static const statistics = AppSection(
    name: 'statistics',
    path: '/statistics',
    label: 'Statystyki',
    subtitle: 'Podsumowania godzin, urlopów i aktywności',
    icon: Icons.insert_chart_outlined,
    type: AppSectionType.primary,
    branchIndex: 1,
  );

  static const notes = AppSection(
    name: 'notes',
    path: '/notes',
    label: 'Notatki',
    subtitle: 'Organizuj prywatne notatki i checklisty',
    icon: Icons.note_alt_outlined,
    type: AppSectionType.primary,
    branchIndex: 2,
  );

  static const settings = AppSection(
    name: 'settings',
    path: '/settings',
    label: 'Ustawienia',
    subtitle: 'Konfiguracja systemu i integracji',
    icon: Icons.settings_outlined,
    type: AppSectionType.drawer,
    branchIndex: 3,
  );

  static const reports = AppSection(
    name: 'reports',
    path: '/reports',
    label: 'Raporty PDF',
    subtitle: 'Generuj i eksportuj meldunki',
    icon: Icons.picture_as_pdf_outlined,
    type: AppSectionType.drawer,
    branchIndex: 4,
  );

  static const subscription = AppSection(
    name: 'subscription',
    path: '/subscription',
    label: 'Subskrypcja',
    subtitle: 'Zarządzaj planem i fakturami',
    icon: Icons.star_outline,
    type: AppSectionType.drawer,
    branchIndex: 5,
  );

  static const help = AppSection(
    name: 'help',
    path: '/help',
    label: 'Pomoc i wsparcie',
    subtitle: 'Centrum wiedzy i kontakt z zespołem',
    icon: Icons.help_center_outlined,
    type: AppSectionType.drawer,
    branchIndex: 6,
  );

  static const all = <AppSection>[
    schedule,
    statistics,
    notes,
    settings,
    reports,
    subscription,
    help,
  ];

  static const primary = <AppSection>[
    schedule,
    statistics,
    notes,
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
