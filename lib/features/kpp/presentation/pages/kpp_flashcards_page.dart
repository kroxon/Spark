import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/kpp/application/kpp_controller.dart';
import 'package:iskra/features/kpp/domain/question.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KppFlashcardsPage extends ConsumerStatefulWidget {
  const KppFlashcardsPage({super.key});

  @override
  ConsumerState<KppFlashcardsPage> createState() => _KppFlashcardsPageState();
}

class _KppFlashcardsPageState extends ConsumerState<KppFlashcardsPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kppState = ref.watch(kppControllerProvider);
    final controller = ref.read(kppControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (kppState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = kppState.filteredQuestions;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Fiszki KPP'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (value) {
              if (value == 'reset_incorrect') {
                controller.resetIncorrect();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Zresetowano błędne odpowiedzi')),
                );
              } else if (value == 'reset_all') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset postępu'),
                    content: const Text('Czy na pewno chcesz usunąć cały postęp nauki?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Anuluj'),
                      ),
                      TextButton(
                        onPressed: () {
                          controller.resetAll();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Postęp został zresetowany')),
                          );
                        },
                        child: const Text('Resetuj'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_incorrect',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Resetuj błędne'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Resetuj wszystko'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      context,
                      title: 'Wszystkie',
                      isSelected: kppState.filter == KppFilter.all,
                      onTap: () => controller.setFilter(KppFilter.all),
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      context,
                      title: 'Do nauki',
                      isSelected: kppState.filter == KppFilter.learning,
                      onTap: () => controller.setFilter(KppFilter.learning),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Twój postęp: ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${kppState.correctCount}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${kppState.totalCount}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${((kppState.correctCount / (kppState.totalCount > 0 ? kppState.totalCount : 1)) * 100).toInt()}%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: [
                          if (kppState.totalCount > 0) ...[
                            Expanded(
                              flex: kppState.correctCount,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green, Colors.lightGreenAccent],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: kppState.incorrectCount,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red, Colors.redAccent],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: kppState.totalCount - kppState.correctCount - kppState.incorrectCount,
                              child: Container(color: theme.colorScheme.surfaceContainerHighest),
                            ),
                          ] else
                            Expanded(child: Container(color: theme.colorScheme.surfaceContainerHighest)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (questions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Wszystkie pytania zaliczone!',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (kppState.filter == KppFilter.learning)
                      TextButton(
                        onPressed: () => controller.setFilter(KppFilter.all),
                        child: const Text('Pokaż wszystkie'),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: questions.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                        });
                      },
                      itemBuilder: (context, index) {
                        return _FlashcardItem(
                          question: questions[index],
                          key: ValueKey(questions[index].id),
                          onAnswer: (isCorrect) {
                            controller.markAnswer(questions[index].id, isCorrect);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, {required String title, required bool isSelected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

}

class _FlashcardItem extends StatefulWidget {
  final KppQuestion question;
  final Function(bool) onAnswer;

  const _FlashcardItem({required this.question, required this.onAnswer, super.key});

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem> {
  int? _selectedAnswerIndex;
  bool _showResult = false;

  void _handleAnswer(int index) {
    if (_showResult) return;
    
    final isCorrect = index == widget.question.correctAnswerIndex;
    
    setState(() {
      _selectedAnswerIndex = index;
      _showResult = true;
    });
    
    widget.onAnswer(isCorrect);
  }


  Color _getOptionColor(int index) {
    if (!_showResult) return Colors.transparent;
    if (index == widget.question.correctAnswerIndex) {
      return Colors.green.withOpacity(0.15);
    }
    if (_selectedAnswerIndex == index && _selectedAnswerIndex != widget.question.correctAnswerIndex) {
      return Colors.red.withOpacity(0.15);
    }
    return Colors.transparent;
  }

  Color _getOptionBorderColor(int index, BuildContext context) {
    if (!_showResult) return Theme.of(context).dividerColor.withOpacity(0.5);
    if (index == widget.question.correctAnswerIndex) {
      return Colors.green;
    }
    if (_selectedAnswerIndex == index && _selectedAnswerIndex != widget.question.correctAnswerIndex) {
      return Colors.red;
    }
    return Theme.of(context).dividerColor.withOpacity(0.5);
  }

  String _indexToLetter(int index) {
    return String.fromCharCode(65 + index); // 0 -> A, 1 -> B, ...
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              widget.question.question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          
          const SizedBox(height: 20),
          
          ...List.generate(widget.question.answers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildOption(context, index, widget.question.answers[index])
                  .animate(delay: (50 * index).ms)
                  .fadeIn()
                  .slideX(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuad),
            );
          }),
          
          if (_showResult && widget.question.explanation != null && widget.question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Wyjaśnienie',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.question.explanation!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, int index, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedAnswerIndex == index;
    final letter = _indexToLetter(index);
    final isCorrect = index == widget.question.correctAnswerIndex;
    final isWrong = isSelected && !isCorrect;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _getOptionColor(index),
        border: Border.all(
          color: _getOptionBorderColor(index, context),
          width: isSelected || (_showResult && isCorrect) ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected || (_showResult && isCorrect)
            ? [
                BoxShadow(
                  color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _handleAnswer(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showResult && isCorrect
                        ? Colors.green
                        : _showResult && isWrong
                            ? Colors.red
                            : isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: _showResult && (isCorrect || isWrong)
                      ? Icon(
                          isCorrect ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          letter,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? null : Colors.grey.shade700,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: _showResult && isCorrect 
                          ? Colors.green 
                          : _showResult && isWrong 
                              ? Colors.red 
                              : null,
                    ),
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
