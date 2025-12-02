import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iskra/features/kpp/application/kpp_controller.dart';
import 'package:iskra/features/kpp/application/kpp_pdf_generator.dart';

class KppMenuPage extends ConsumerWidget {
  const KppMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Nauka KPP'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.blueGrey.shade900, Colors.blue.shade900]
                        : [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 160,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildMenuCard(
                    context,
                    title: 'Fiszki',
                    description: 'Przeglądaj pytania i sprawdzaj swoją wiedzę.',
                    icon: Icons.style_rounded,
                    color: Colors.blueAccent,
                    gradientColors: [Colors.blueAccent, Colors.lightBlueAccent],
                    onTap: () => context.pushNamed(AppRouteName.kppFlashcards),
                    delay: 200.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    context,
                    title: 'Egzamin Próbny',
                    description: 'Symulacja egzaminu. 30 pytań, 30 minut.',
                    icon: Icons.timer_outlined,
                    color: Colors.orangeAccent,
                    gradientColors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                    onTap: () => context.pushNamed(AppRouteName.kppExam),
                    delay: 400.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    context,
                    title: 'Generator Arkusza',
                    description: 'Pobierz PDF z losowym testem do druku.',
                    icon: Icons.print_rounded,
                    color: Colors.purpleAccent,
                    gradientColors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                    onTap: () => _showPdfConfirmationDialog(context, ref),
                    delay: 600.ms,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPdfConfirmationDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generowanie Arkusza'),
        content: const Text(
          'Czy chcesz wygenerować nowy arkusz egzaminacyjny w formacie PDF? '
          'Zawiera on 30 losowych pytań.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generuj'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _generatePdfWithLoading(context, ref);
    }
  }

  Future<void> _generatePdfWithLoading(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Stack(
          children: [
            // Blurred background
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: BackdropFilter(
                  filter:  ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(strokeWidth: 6),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 1.seconds),
                    const SizedBox(height: 24),
                    Text(
                      'Generowanie arkusza...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proszę czekać',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack).fadeIn(),
            ),
          ],
        ),
      ),
    );

    // Simulate a small delay for the "professional" feel and to let the UI render
    await Future.delayed(const Duration(seconds: 2));

    try {
      final repo = ref.read(kppRepositoryProvider);
      final questions = await repo.getQuestions();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (questions.isNotEmpty) {
        await KppPdfGenerator.generateExamSheet(questions);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Błąd: Brak pytań w bazie.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd generowania PDF: $e')),
        );
      }
    }
  }


  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required Duration delay,
    bool isLocked = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLocked ? [Colors.grey.shade400, Colors.grey.shade600] : gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isLocked ? Colors.grey : color).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLocked ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(isLocked ? 0.5 : 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: delay).fadeIn().slideY(begin: 0.2, end: 0);
  }
}
