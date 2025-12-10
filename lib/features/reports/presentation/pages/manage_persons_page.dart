import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/common_widgets/app_text_field.dart';
import 'package:iskra/features/reports/domain/report_person.dart';
import 'package:iskra/features/reports/presentation/report_providers.dart';

class ManagePersonsPage extends ConsumerStatefulWidget {
  final bool showAppBar;
  const ManagePersonsPage({super.key, this.showAppBar = true});

  @override
  ConsumerState<ManagePersonsPage> createState() => _ManagePersonsPageState();
}

class _ManagePersonsPageState extends ConsumerState<ManagePersonsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
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
    final personsAsync = ref.watch(savedPersonsProvider);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: const Text('Zarządzaj Osobami'))
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              label: 'Szukaj osoby...',
              prefixIcon: Icons.search,
            ),
          ),
          Expanded(
            child: personsAsync.when(
              data: (persons) {
                final filteredPersons = persons.where((p) {
                  final fullName = p.fullName.toLowerCase();
                  final rank = p.rank.toLowerCase();
                  return fullName.contains(_searchQuery) ||
                      rank.contains(_searchQuery);
                }).toList();

                if (filteredPersons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Brak zapisanych osób. Dodaj kogoś!'
                              : 'Nie znaleziono osób pasujących do zapytania.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPersons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final person = filteredPersons[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            person.firstName.isNotEmpty
                                ? person.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(person.rank,
                                style: TextStyle(color: Colors.grey[700])),
                            if (person.unit.isNotEmpty)
                              Text(person.unit,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showPersonDialog(context, ref,
                                  person: person),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, ref, person),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Błąd: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPersonDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj osobę'),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ReportPerson person) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń osobę'),
        content: Text('Czy na pewno chcesz usunąć ${person.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Anuluj')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Usuń')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreReportRepositoryProvider).deletePerson(person.id);
    }
  }

  void _showPersonDialog(BuildContext context, WidgetRef ref,
      {ReportPerson? person}) {
    showDialog(
      context: context,
      builder: (context) => _PersonDialog(person: person),
    );
  }
}

class _PersonDialog extends ConsumerStatefulWidget {
  final ReportPerson? person;

  const _PersonDialog({this.person});

  @override
  ConsumerState<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends ConsumerState<_PersonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _rankCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _unitCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl =
        TextEditingController(text: widget.person?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.person?.lastName ?? '');
    _rankCtrl = TextEditingController(text: widget.person?.rank ?? '');
    _positionCtrl = TextEditingController(text: widget.person?.position ?? '');
    _unitCtrl = TextEditingController(text: widget.person?.unit ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _rankCtrl.dispose();
    _positionCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newPerson = ReportPerson(
      id: widget.person?.id ?? '',
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      rank: _rankCtrl.text,
      position: _positionCtrl.text,
      unit: _unitCtrl.text,
    );

    final repo = ref.read(firestoreReportRepositoryProvider);
    if (widget.person == null) {
      await repo.addPerson(newPerson);
    } else {
      await repo.updatePerson(newPerson);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.person == null ? 'Dodaj osobę' : 'Edytuj osobę',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _rankCtrl,
                  label: 'Stopień',
                  validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _firstNameCtrl,
                  label: 'Imię',
                  validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _lastNameCtrl,
                  label: 'Nazwisko',
                  validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _positionCtrl,
                  label: 'Stanowisko',
                  validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _unitCtrl,
                  label: 'Jednostka (opcjonalne)',
                  // No validator needed as it is optional
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Zapisz'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
