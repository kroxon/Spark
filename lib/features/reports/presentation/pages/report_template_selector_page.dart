import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/common_widgets/app_text_field.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/reports/domain/report_template.dart';
import 'package:iskra/features/reports/presentation/pages/manage_persons_page.dart';
import 'package:iskra/features/reports/presentation/report_providers.dart';

class ReportTemplateSelectorPage extends ConsumerWidget {
  const ReportTemplateSelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generator Raportów'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Szablony', icon: Icon(Icons.description_outlined)),
              Tab(text: 'Osoby', icon: Icon(Icons.people_outline)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'templates') {
                  context.pushNamed(AppRouteName.reportManageTemplates);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'templates',
                  child: Row(
                    children: [
                      Icon(Icons.copy, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Zarządzaj Szablonami'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _TemplatesTab(),
            ManagePersonsPage(showAppBar: false),
          ],
        ),
      ),
    );
  }
}

class _TemplatesTab extends ConsumerStatefulWidget {
  const _TemplatesTab();

  @override
  ConsumerState<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends ConsumerState<_TemplatesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(allTemplatesProvider);

    final filteredTemplates = templates.where((t) {
      final query = _searchQuery.toLowerCase();
      return t.name.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              label: 'Szukaj szablonu...',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: filteredTemplates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Brak dostępnych szablonów.'
                              : 'Nie znaleziono szablonów.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: template.isSystem
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              template.isSystem
                                  ? Icons.description
                                  : Icons.star,
                              color: template.isSystem
                                  ? Theme.of(context).primaryColor
                                  : Colors.orange,
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              template.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                          onTap: () {
                            context.pushNamed(
                              AppRouteName.reportEditor,
                              extra: template,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create a new empty template and navigate to editor
          final newTemplate = ReportTemplate(
            id: '', // Will be generated
            name: 'Nowy Raport',
            description: 'Opis nowego raportu',
            defaultContent: '',
            isSystem: false,
          );
          context.pushNamed(
            AppRouteName.reportEditor,
            extra: newTemplate,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Stwórz własny'),
      ),
    );
  }
}
