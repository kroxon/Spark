import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/reports/data/pdf_report_service.dart';
import 'package:iskra/features/reports/domain/report_person.dart';
import 'package:iskra/features/reports/domain/report_template.dart';
import 'package:iskra/features/reports/presentation/report_providers.dart';

class ReportEditorPage extends ConsumerStatefulWidget {
  final ReportTemplate template;

  const ReportEditorPage({super.key, required this.template});

  @override
  ConsumerState<ReportEditorPage> createState() => _ReportEditorPageState();
}

class _ReportEditorPageState extends ConsumerState<ReportEditorPage> {
  // Controllers
  late TextEditingController _topicController;
  late TextEditingController _intentController;
  late TextEditingController _contentController;
  late TextEditingController _cityController;

  // State
  ReportPerson? _selectedSender;
  ReportPerson? _selectedRecipient;
  bool _isGenerating = false;
  bool _showContentEditor = false;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.template.name);
    _intentController = TextEditingController();
    _contentController = TextEditingController(text: widget.template.defaultContent);
    _cityController = TextEditingController(text: 'Warszawa'); // TODO: Get from user prefs
    
    // If template has content, show editor immediately
    if (widget.template.defaultContent.isNotEmpty && widget.template.defaultContent != "...") {
      _showContentEditor = true;
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _intentController.dispose();
    _contentController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // --- AI Logic ---

  Future<void> _generateContent() async {
    final intent = _intentController.text;
    if (intent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wpisz co chcesz uzyskać (intencję)')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final aiService = ref.read(reportAiServiceProvider);
      
      // 1. Suggest topic if empty
      if (_topicController.text.isEmpty) {
        final suggestedTopic = await aiService.suggestTopic(intent);
        if (mounted) _topicController.text = suggestedTopic;
      }

      // 2. Generate content
      final generatedContent = await aiService.generateReportFromIntent(
        intent: intent,
        topic: _topicController.text,
        currentContent: _contentController.text,
      );

      if (mounted) {
        _contentController.text = generatedContent;
        setState(() => _showContentEditor = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd AI: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- PDF Logic ---

  Future<void> _generatePdf() async {
    if (_selectedSender == null || _selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz nadawcę i odbiorcę')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final pdfService = ref.read(pdfReportServiceProvider);
      final pdfData = await pdfService.generateReport(
        city: _cityController.text,
        date: DateTime.now(),
        sender: _selectedSender!,
        recipient: _selectedRecipient!,
        title: _topicController.text,
        body: _contentController.text,
        fontType: ReportFont.timesNewRoman,
      );

      if (mounted) {
        context.pushNamed(
          AppRouteName.reportPdfPreview,
          extra: {
            'pdfData': pdfData,
            'fileName': '${_topicController.text}.pdf',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Błąd PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- Save Template Logic ---

  Future<void> _saveAsTemplate() async {
    final nameController = TextEditingController(text: _topicController.text);
    final descController = TextEditingController(text: 'Mój własny szablon');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zapisz jako szablon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nazwa szablonu'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Opis'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Zapisz')),
        ],
      ),
    );

    if (shouldSave == true) {
      final newTemplate = ReportTemplate(
        name: nameController.text,
        description: descController.text,
        defaultContent: _contentController.text,
        isSystem: false,
      );
      
      await ref.read(firestoreReportRepositoryProvider).addTemplate(newTemplate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Szablon zapisany!')),
        );
      }
    }
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final personsAsync = ref.watch(savedPersonsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edytor Raportu'),
        actions: [
          if (_showContentEditor)
            IconButton(
              icon: const Icon(Icons.save_as),
              onPressed: _saveAsTemplate,
              tooltip: 'Zapisz jako szablon',
            ),
        ],
      ),
      body: personsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Błąd: $err')),
        data: (persons) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Persons Section
                _buildSectionHeader('1. Dane podstawowe'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ReportPerson>(
                        value: _selectedSender,
                        decoration: const InputDecoration(
                          labelText: 'Nadawca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: persons.map((p) => DropdownMenuItem(value: p, child: Text(p.fullName))).toList(),
                        onChanged: (val) => setState(() => _selectedSender = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () => context.pushNamed(AppRouteName.reportManagePersons),
                      tooltip: 'Dodaj osobę',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportPerson>(
                  value: _selectedRecipient,
                  decoration: const InputDecoration(
                    labelText: 'Odbiorca',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: persons.map((p) => DropdownMenuItem(value: p, child: Text('${p.rank} ${p.lastName} (${p.position})'))).toList(),
                  onChanged: (val) => setState(() => _selectedRecipient = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Miejscowość',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),

                const SizedBox(height: 24),

                // 2. AI / Intent Section
                _buildSectionHeader('2. Treść i AI'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Temat (opcjonalne)',
                    hintText: 'np. Wniosek o urlop',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _intentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Co chcesz napisać? (Intencja)',
                    hintText: 'np. Proszę o wolne na dziecko w dniu 12.12 bo zachorowało.',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.orange),
                      onPressed: _isGenerating ? null : _generateContent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_isGenerating)
                  const LinearProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: _generateContent,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_showContentEditor ? 'Przeredaguj z AI' : 'Generuj treść'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  ),

                // 3. Editor Section
                if (_showContentEditor) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('3. Edycja i Podgląd'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tutaj pojawi się treść raportu...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _isGenerating ? null : _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generuj PDF'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
