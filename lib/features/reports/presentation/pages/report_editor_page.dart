import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:iskra/features/reports/data/pdf_report_service.dart';
import 'package:iskra/features/reports/domain/report_person.dart';
import 'package:iskra/features/reports/domain/report_template.dart';
import 'package:iskra/features/reports/presentation/report_providers.dart';
import 'package:iskra/common_widgets/shimmer_skeleton.dart';

class ReportEditorPage extends ConsumerStatefulWidget {
  final ReportTemplate template;

  const ReportEditorPage({super.key, required this.template});

  @override
  ConsumerState<ReportEditorPage> createState() => _ReportEditorPageState();
}

class _ReportEditorPageState extends ConsumerState<ReportEditorPage> with TickerProviderStateMixin {
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

  // Animations
  late AnimationController _entryAnimationController;

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

    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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
    _entryAnimationController.dispose();
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
      
      // 1. Always suggest topic based on intent (AI inference)
      final suggestedTopic = await aiService.suggestTopic(intent);
      if (mounted) _topicController.text = suggestedTopic;

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

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('Zapisz szablon jako', style: TextStyle(fontWeight: FontWeight.bold))),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Wpisz nazwę szablonu...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Anuluj',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Zapisz', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      final newTemplate = ReportTemplate(
        name: nameController.text,
        description: '',
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final double iconSize = isSmallScreen ? 18 : 24;
    final double fontSize = isSmallScreen ? 13 : 16;
    final double labelFontSize = isSmallScreen ? 12 : 14;

    Widget buildPersonDropdown(
      List<ReportPerson> persons,
      ReportPerson? value,
      String label,
      IconData icon,
      ValueChanged<ReportPerson?> onChanged,
    ) {
      final sortedPersons = List<ReportPerson>.from(persons)
        ..sort((a, b) => a.lastName.compareTo(b.lastName));

      return _ModernDropdown(
        value: value,
        items: sortedPersons,
        label: label,
        icon: icon,
        onChanged: onChanged,
        fontSize: fontSize,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edytor Raportu', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_showContentEditor)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _saveAsTemplate,
                icon: Icon(Icons.save_as_outlined, color: Theme.of(context).colorScheme.onSurface),
                label: Text(
                  'Zapisz szablon',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainer,
                  ]
                : [
                    const Color(0xFFFFF3E0), // Warm Orange tint
                    const Color(0xFFF3E5F5), // Soft Purple tint
                  ],
          ),
        ),
        child: SafeArea(
          child: personsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Błąd: $err')),
            data: (persons) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Persons Section
                    _SlideIn(
                      delay: 0,
                      controller: _entryAnimationController,
                      child: _ModernGlassCard(
                        child: _buildCollapsibleSection(
                          title: '1. Dane podstawowe',
                          isExpanded: _isBasicDataExpanded,
                          onToggle: () => setState(() => _isBasicDataExpanded = !_isBasicDataExpanded),
                          children: [
                            const SizedBox(height: 8),
                            buildPersonDropdown(
                              persons,
                              _selectedSender,
                              'Nadawca',
                              Icons.person_rounded,
                              (val) => setState(() => _selectedSender = val),
                            ),
                            const SizedBox(height: 16),
                            buildPersonDropdown(
                              persons,
                              _selectedRecipient,
                              'Odbiorca',
                              Icons.person_outline_rounded,
                              (val) => setState(() => _selectedRecipient = val),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => context.pushNamed(AppRouteName.reportManagePersons),
                                icon: Icon(Icons.manage_accounts_outlined, size: iconSize),
                                label: Text(
                                  'Zarządzaj listą osób',
                                  style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600),
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ModernTextField(
                              controller: _cityController,
                              label: 'Miejscowość',
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 16),
                            _ModernTextField(
                              controller: _dateController,
                              label: 'Data',
                              readOnly: true,
                              fontSize: fontSize,
                              suffixIcon: Icons.keyboard_arrow_down_rounded,
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
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. AI / Intent Section
                    _SlideIn(
                      delay: 100,
                      controller: _entryAnimationController,
                      child: _ModernGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('2. Opis sprawy'),
                            const SizedBox(height: 16),
                            _ModernTextField(
                              controller: _intentController,
                              label: 'Opisz krótko cel i treść raportu',
                              hintText: 'np. raport dotyczący wymiany ubrania specjalnego',
                              maxLines: 3,
                              fontSize: fontSize,
                            ),
                            const SizedBox(height: 16),
                            _AnimatedGradientButton(
                              isLoading: _isGenerating,
                              onPressed: _generateContent,
                              label: _showContentEditor ? 'Przeredaguj z AI' : 'Generuj treść',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Editor Section
                    AnimatedSize(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutQuart,
                      child: (_showContentEditor || _isGenerating)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: _ModernGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionHeader('3. Edycja i Podgląd'),
                                    const SizedBox(height: 16),
                                    if (_isGenerating)
                                      _build3DLoadingField(
                                        height: 64,
                                        child: const Align(
                                          alignment: Alignment.centerLeft,
                                          child: ShimmerSkeleton(height: 16, width: 200, borderRadius: 4),
                                        ),
                                      )
                                    else
                                      _ModernTextField(
                                        controller: _topicController,
                                        label: 'Temat',
                                        fontSize: fontSize,
                                      ),
                                    const SizedBox(height: 16),
                                    if (_isGenerating)
                                      _build3DLoadingField(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            for (int i = 0; i < 6; i++)
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 12.0),
                                                child: ShimmerSkeleton(
                                                  height: 14, 
                                                  borderRadius: 4,
                                                  width: i == 5 ? 150 : double.infinity,
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    else
                                      _ModernTextField(
                                        controller: _contentController,
                                        label: 'Treść',
                                        hintText: 'Tutaj pojawi się treść raportu...',
                                        maxLines: 10,
                                        fontSize: fontSize,
                                      ),
                                    const SizedBox(height: 24),
                                    if (!_isGenerating)
                                      FilledButton.icon(
                                        onPressed: _generatePdf,
                                        icon: const Icon(Icons.picture_as_pdf_rounded),
                                        label: const Text('Generuj PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size.fromHeight(56),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 2,
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _build3DLoadingField({required Widget child, double? height}) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
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
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpanded 
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
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
                              color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
                            color: isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
                    padding: const EdgeInsets.only(top: 16.0),
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
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }
}

// --- Modern UI Components ---

class _ModernGlassCard extends StatelessWidget {
  final Widget child;
  const _ModernGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;
  final double fontSize;

  const _ModernTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: fontSize - 1, fontWeight: FontWeight.w500),
          prefixIcon: icon != null ? Icon(icon, color: colorScheme.onSurfaceVariant, size: 22) : null,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: colorScheme.onSurfaceVariant, size: 22) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final ReportPerson? value;
  final List<ReportPerson> items;
  final String label;
  final IconData icon;
  final ValueChanged<ReportPerson?> onChanged;
  final double fontSize;

  const _ModernDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.onChanged,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DropdownButtonFormField<ReportPerson>(
        isExpanded: true,
        value: value,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: fontSize - 1, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: colorScheme.surfaceContainer,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        menuMaxHeight: 300,
        selectedItemBuilder: (context) {
          return items.map((p) {
            return Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
                  children: [
                    TextSpan(
                      text: '${p.lastName} ${p.firstName} ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: '(${p.rank}${p.title.isNotEmpty ? ' ${p.title}' : ''})',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: fontSize * 0.85,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        items: items.map((p) {
          return DropdownMenuItem(
            value: p,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: fontSize),
                  children: [
                    TextSpan(
                      text: '${p.lastName} ${p.firstName} ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    TextSpan(
                      text: '(${p.rank}${p.title.isNotEmpty ? ' ${p.title}' : ''})',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: fontSize * 0.85,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _AnimatedGradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const _AnimatedGradientButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)], // Orange gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F00).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final AnimationController controller;

  const _SlideIn({required this.child, required this.delay, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final start = delay / 1000.0; // Simple delay logic
        final end = start + 0.4;
        
        final curve = CurvedAnimation(
          parent: controller,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutQuart),
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(curve),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

