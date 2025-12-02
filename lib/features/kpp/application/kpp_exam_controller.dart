import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/kpp/application/kpp_controller.dart';
import 'package:iskra/features/kpp/data/kpp_repository.dart';
import 'package:iskra/features/kpp/domain/question.dart';

enum KppExamStatus { initial, inProgress, finished }

class KppExamState {
  final List<KppQuestion> questions;
  final Map<int, int> userAnswers; // questionId -> answerIndex
  final int currentQuestionIndex;
  final int timeLeftInSeconds;
  final KppExamStatus status;
  final bool isLoading;

  const KppExamState({
    this.questions = const [],
    this.userAnswers = const {},
    this.currentQuestionIndex = 0,
    this.timeLeftInSeconds = 30 * 60, // 30 minutes
    this.status = KppExamStatus.initial,
    this.isLoading = false,
  });

  int get score {
    int correct = 0;
    for (var question in questions) {
      if (userAnswers[question.id] == question.correctAnswerIndex) {
        correct++;
      }
    }
    return correct;
  }

  bool get isPassed => score >= 27; // Assuming 90% pass rate for 30 questions (standard KPP is usually high)

  KppExamState copyWith({
    List<KppQuestion>? questions,
    Map<int, int>? userAnswers,
    int? currentQuestionIndex,
    int? timeLeftInSeconds,
    KppExamStatus? status,
    bool? isLoading,
  }) {
    return KppExamState(
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      timeLeftInSeconds: timeLeftInSeconds ?? this.timeLeftInSeconds,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class KppExamController extends Notifier<KppExamState> {
  Timer? _timer;
  late final KppRepository _repository;

  @override
  KppExamState build() {
    _repository = ref.watch(kppRepositoryProvider);
    return const KppExamState();
  }

  Future<void> startExam() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final allQuestions = await _repository.getQuestions();
      if (allQuestions.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Randomly select 30 questions
      final random = Random();
      final List<KppQuestion> selectedQuestions = [];
      final List<KppQuestion> pool = List.from(allQuestions);
      
      final count = min(30, pool.length);
      for (int i = 0; i < count; i++) {
        final index = random.nextInt(pool.length);
        selectedQuestions.add(pool[index]);
        pool.removeAt(index);
      }

      state = KppExamState(
        questions: selectedQuestions,
        status: KppExamStatus.inProgress,
        timeLeftInSeconds: 30 * 60,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeftInSeconds > 0) {
        state = state.copyWith(timeLeftInSeconds: state.timeLeftInSeconds - 1);
      } else {
        finishExam();
      }
    });
  }

  void selectAnswer(int questionId, int answerIndex) {
    if (state.status != KppExamStatus.inProgress) return;

    final newAnswers = Map<int, int>.from(state.userAnswers);
    newAnswers[questionId] = answerIndex;
    state = state.copyWith(userAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  void finishExam() {
    _timer?.cancel();
    state = state.copyWith(status: KppExamStatus.finished);
  }

  void resetExam() {
    _timer?.cancel();
    state = const KppExamState();
  }
}

final kppExamControllerProvider = NotifierProvider<KppExamController, KppExamState>(() {
  return KppExamController();
});
