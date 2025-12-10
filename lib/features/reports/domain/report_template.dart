class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final String defaultContent;
  final bool isSystem;

  const ReportTemplate({
    this.id = '',
    required this.name,
    required this.description,
    required this.defaultContent,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'defaultContent': defaultContent,
      'isSystem': isSystem,
    };
  }

  factory ReportTemplate.fromMap(Map<String, dynamic> map, String documentId) {
    return ReportTemplate(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      defaultContent: map['defaultContent'] ?? '',
      isSystem: map['isSystem'] ?? false,
    );
  }

  static const List<ReportTemplate> predefinedTemplates = [
    ReportTemplate(
      id: 'sys_urlop_ojcowski',
      name: "Urlop Ojcowski",
      description: "Wniosek o urlop ojcowski",
      defaultContent: "Zwracam się z prośbą o udzielenie urlopu ojcowskiego w wymiarze ... dni w terminie od ... do ... w związku z urodzeniem się dziecka ...",
      isSystem: true,
    ),
    ReportTemplate(
      id: 'sys_opieka_188',
      name: "Opieka nad dzieckiem (art. 188 KP)",
      description: "Zwolnienie od pracy na opiekę",
      defaultContent: "Zwracam się z prośbą o udzielenie zwolnienia od pracy na opiekę nad dzieckiem do lat 14 (art. 188 KP) w dniu ...",
      isSystem: true,
    ),
    ReportTemplate(
      id: 'sys_wymiana_umundurowania',
      name: "Wymiana umundurowania",
      description: "Raport o wymianę zużytych sortów",
      defaultContent: "Zwracam się z prośbą o wymianę zużytych elementów umundurowania: ...",
      isSystem: true,
    ),
    ReportTemplate(
      id: 'sys_notatka',
      name: "Notatka służbowa",
      description: "Ogólny wzór notatki",
      defaultContent: "W dniu ... w trakcie pełnienia służby ...",
      isSystem: true,
    ),
  ];
}
