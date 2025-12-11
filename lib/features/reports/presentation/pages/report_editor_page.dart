import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _dateController;

  // State
  ReportPerson? _selectedSender;
  ReportPerson? _selectedRecipient;
  DateTime _selectedDate = DateTime.now();
  bool _isGenerating = false;
  bool _showContentEditor = false;
  bool _isBasicDataExpanded = true;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.template.name);
    _intentController = TextEditingController();
    _contentController = TextEditingController(text: widget.template.defaultContent);
    _cityController = TextEditingController(text: '');
    _dateController = TextEditingController(text: DateFormat('dd.MM.yyyy').format(_selectedDate));
    
    _loadLastCity();

    // If template has content, show editor immediately
    if (widget.template.defaultContent.isNotEmpty && widget.template.defaultContent != "...") {
      _showContentEditor = true;
    }
  }

  Future<void> _loadLastCity() async {
    final city = await ref.read(firestoreReportRepositoryProvider).getLastCity();
    if (city != null && mounted) {
      setState(() {
        _cityController.text = city;
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _intentController.dispose();
    _contentController.dispose();
    _cityController.dispose();
    _dateController.dispose();
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
      // Save city for future use
      if (_cityController.text.isNotEmpty) {
        await ref.read(firestoreReportRepositoryProvider).saveLastCity(_cityController.text);
      }

      final pdfService = ref.read(pdfReportServiceProvider);
      final pdfData = await pdfService.generateReport(
        city: _cityController.text,
        date: _selectedDate,
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
    
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final double iconSize = isSmallScreen ? 18 : 24;
    final double fontSize = isSmallScreen ? 13 : 16;
    final double labelFontSize = isSmallScreen ? 12 : 14;

    InputDecoration responsiveDecoration(String label, IconData icon, {IconData? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: labelFontSize),
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, size: iconSize),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: iconSize) : null,
        contentPadding: isSmallScreen ? const EdgeInsets.symmetric(horizontal: 8, vertical: 12) : null,
        isDense: isSmallScreen,
      );
    }

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
                _buildCollapsibleSection(
                  title: '1. Dane podstawowe',
                  isExpanded: _isBasicDataExpanded,
                  onToggle: () => setState(() => _isBasicDataExpanded = !_isBasicDataExpanded),
                  children: [
                    DropdownButtonFormField<ReportPerson>(
                      isExpanded: true,
                      value: _selectedSender,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: fontSize),
                      decoration: responsiveDecoration('Nadawca', Icons.person),
                      items: persons
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              )))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSender = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ReportPerson>(
                      isExpanded: true,
                      value: _selectedRecipient,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: fontSize),
                      decoration: responsiveDecoration('Odbiorca', Icons.person_outline),
                      items: persons
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                '${p.rank} ${p.lastName} (${p.position})',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: fontSize),
                              )))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedRecipient = val),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.pushNamed(AppRouteName.reportManagePersons),
                        icon: Icon(Icons.manage_accounts_outlined, size: iconSize),
                        label: Text(
                          'Zarządzaj listą osób',
                          style: TextStyle(fontSize: labelFontSize),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _cityController,
                      style: TextStyle(fontSize: fontSize),
                      decoration: responsiveDecoration('Miejscowość', Icons.location_city),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      style: TextStyle(fontSize: fontSize),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme,
                                dialogBackgroundColor: Theme.of(context).colorScheme.surface,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                            _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
                          });
                        }
                      },
                      decoration: responsiveDecoration('Data', Icons.calendar_today, suffixIcon: Icons.arrow_drop_down),
                    ),
                  ],
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

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpanded 
                          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isExpanded ? 'Zwiń' : 'Rozwiń',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutBack,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          child: SizedBox(
            width: double.infinity,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
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
