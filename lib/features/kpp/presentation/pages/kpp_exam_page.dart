import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iskra/features/kpp/application/kpp_exam_controller.dart';
import 'package:iskra/features/kpp/domain/question.dart';
import 'package:go_router/go_router.dart';

class KppExamPage extends ConsumerStatefulWidget {
  const KppExamPage({super.key});

  @override
  ConsumerState<KppExamPage> createState() => _KppExamPageState();
}

class _KppExamPageState extends ConsumerState<KppExamPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Start exam if not already in progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(kppExamControllerProvider);
      if (state.status == KppExamStatus.initial) {
        ref.read(kppExamControllerProvider.notifier).startExam();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kppExamControllerProvider);
    final controller = ref.read(kppExamControllerProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen to index changes to animate page view
    ref.listen(kppExamControllerProvider.select((s) => s.currentQuestionIndex), (prev, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.status == KppExamStatus.finished) {
      return _buildResultPage(context, state, theme, isDark);
    }

    if (state.questions.isEmpty) {
      return const Scaffold(body: Center(child: Text('Brak pytań')));
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final minutes = (state.timeLeftInSeconds / 60).floor();
    final seconds = state.timeLeftInSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isTimeLow = state.timeLeftInSeconds < 60;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              color: isTimeLow ? Colors.red : theme.colorScheme.primary,
            ).animate(target: isTimeLow ? 1 : 0).shake(hz: 2),
            const SizedBox(width: 8),
            Text(
              timeString,
              style: theme.textTheme.titleLarge?.copyWith(
                color: isTimeLow ? Colors.red : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _showFinishDialog(context, controller),
            child: const Text('Zakończ'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (state.currentQuestionIndex + 1) / state.questions.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 4,
          ),
          
          // Question Counter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pytanie ${state.currentQuestionIndex + 1} / ${state.questions.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.userAnswers.containsKey(currentQuestion.id))
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      .animate()
                      .scale(),
              ],
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: state.questions.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                controller.jumpToQuestion(index);
              },
              itemBuilder: (context, index) {
                return _ExamQuestionCard(
                  question: state.questions[index],
                  selectedAnswerIndex: state.userAnswers[state.questions[index].id],
                  onAnswerSelected: (answerIndex) {
                    controller.selectAnswer(state.questions[index].id, answerIndex);
                    // Optional: Auto-advance after delay? No, in exam mode user usually stays to review.
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: state.currentQuestionIndex > 0 ? controller.previousQuestion : null,
              icon: const Icon(Icons.arrow_back_ios_new),
            ),
            
            // Quick Navigation Grid Trigger could go here
            IconButton(
              onPressed: () => _showQuestionGrid(context, state, controller),
              icon: const Icon(Icons.grid_view_rounded),
            ),

            IconButton(
              onPressed: state.currentQuestionIndex < state.questions.length - 1 
                  ? controller.nextQuestion 
                  : () => _showFinishDialog(context, controller),
              icon: Icon(
                state.currentQuestionIndex < state.questions.length - 1 
                    ? Icons.arrow_forward_ios 
                    : Icons.check_circle_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishDialog(BuildContext context, KppExamController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zakończyć egzamin?'),
        content: const Text('Czy na pewno chcesz zakończyć egzamin i sprawdzić wyniki?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wróć'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              controller.finishExam();
            },
            child: const Text('Zakończ'),
          ),
        ],
      ),
    );
  }

  void _showQuestionGrid(BuildContext context, KppExamState state, KppExamController controller) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: state.questions.length,
            itemBuilder: (context, index) {
              final isAnswered = state.userAnswers.containsKey(state.questions[index].id);
              final isCurrent = index == state.currentQuestionIndex;
              
              Color backgroundColor;
              Color contentColor;
              List<BoxShadow> shadows = [];
              Widget content;

              if (isCurrent) {
                backgroundColor = theme.colorScheme.primary;
                contentColor = theme.colorScheme.onPrimary;
                shadows = [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ];
                content = Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              } else if (isAnswered) {
                backgroundColor = theme.colorScheme.primaryContainer;
                contentColor = theme.colorScheme.primary;
                content = Icon(
                  Icons.check_rounded,
                  color: contentColor,
                  size: 28,
                ).animate().scale(duration: 200.ms, curve: Curves.elasticOut);
              } else {
                backgroundColor = theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
                contentColor = theme.colorScheme.onSurfaceVariant;
                content = Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: contentColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                );
              }

              return InkWell(
                onTap: () {
                  controller.jumpToQuestion(index);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: shadows,
                  ),
                  alignment: Alignment.center,
                  child: content,
                ),
              ).animate().scale(delay: (index * 10).ms, duration: 200.ms, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultPage(BuildContext context, KppExamState state, ThemeData theme, bool isDark) {
    final score = state.score;
    final total = state.questions.length;
    final percentage = (score / total * 100).toInt();
    final isPassed = state.isPassed;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                size: 100,
                color: isPassed ? Colors.amber : Colors.red,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).then().shimmer(),
              
              const SizedBox(height: 24),
              
              Text(
                isPassed ? 'Gratulacje!' : 'Niestety...',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.green : Colors.red,
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                isPassed ? 'Zdałeś egzamin próbny' : 'Nie udało się zaliczyć egzaminu',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 48),
              
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed ? Colors.green : Colors.red).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentage%',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '$score / $total',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms),
              
              const SizedBox(height: 48),
              
              FilledButton.icon(
                onPressed: () {
                  ref.read(kppExamControllerProvider.notifier).resetExam();
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Wróć do menu'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExamQuestionCard extends StatelessWidget {
  final KppQuestion question;
  final int? selectedAnswerIndex;
  final Function(int) onAnswerSelected;

  const _ExamQuestionCard({
    required this.question,
    required this.selectedAnswerIndex,
    required this.onAnswerSelected,
  });

  String _indexToLetter(int index) {
    return String.fromCharCode(65 + index);
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
              question.question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          ...List.generate(question.answers.length, (index) {
            final isSelected = selectedAnswerIndex == index;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onAnswerSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primaryContainer 
                        : isDark ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) : Colors.white,
                    border: Border.all(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _indexToLetter(index),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? theme.colorScheme.onPrimary 
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          question.answers[index],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
