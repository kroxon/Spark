import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/reports/domain/report_template.dart';
import 'package:iskra/features/reports/presentation/report_providers.dart';

class ManageTemplatesPage extends ConsumerWidget {
  const ManageTemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(customTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoje Szablony'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Text('Brak własnych szablonów.'),
            );
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, ref, template),
                ),
                // Edycja szablonu może być bardziej skomplikowana, na razie tylko usuwanie
                // lub podgląd.
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ReportTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń szablon'),
        content: Text('Czy na pewno chcesz usunąć szablon "${template.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreReportRepositoryProvider).deleteTemplate(template.id);
    }
  }
}
