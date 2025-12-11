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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Szukaj osoby...',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Theme.of(context).hintColor),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
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

                filteredPersons
                    .sort((a, b) => a.lastName.compareTo(b.lastName));

                if (filteredPersons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Brak zapisanych osób'
                              : 'Nie znaleziono osób',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredPersons.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final person = filteredPersons[index];
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: isDark
                            ? theme.colorScheme.surfaceContainer
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _showPersonDialog(context, ref,
                              person: person),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary
                                            .withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      person.lastName.isNotEmpty
                                          ? person.lastName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${person.lastName} ${person.firstName}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        person.title.isNotEmpty
                                            ? '${person.rank} ${person.title}'
                                            : person.rank,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (person.position.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            person.position,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      if (person.unit.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Row(
                                            children: [
                                              Text(
                                                person.unit,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 20),
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                      onPressed: () => _showPersonDialog(
                                          context, ref,
                                          person: person),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded,
                                          size: 20),
                                      color: theme.colorScheme.error
                                          .withOpacity(0.7),
                                      onPressed: () =>
                                          _confirmDelete(context, ref, person),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
  late TextEditingController _titleCtrl;
  late TextEditingController _positionCtrl;
  late TextEditingController _unitCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl =
        TextEditingController(text: widget.person?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.person?.lastName ?? '');
    _rankCtrl = TextEditingController(text: widget.person?.rank ?? '');
    _titleCtrl = TextEditingController(text: widget.person?.title ?? '');
    _positionCtrl = TextEditingController(text: widget.person?.position ?? '');
    _unitCtrl = TextEditingController(text: widget.person?.unit ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _rankCtrl.dispose();
    _titleCtrl.dispose();
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
      title: _titleCtrl.text,
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
                  controller: _titleCtrl,
                  label: 'Tytuł naukowy (opcjonalne)',
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
