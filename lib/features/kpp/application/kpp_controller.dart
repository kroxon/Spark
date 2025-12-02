import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/kpp/data/kpp_repository.dart';
import 'package:iskra/features/kpp/data/kpp_progress_repository.dart';
import 'package:iskra/features/kpp/domain/question.dart';

enum KppFilter { all, learning }

class KppState {
  final List<KppQuestion> allQuestions;
  final List<KppQuestion> filteredQuestions;
  final Map<int, bool> progress; // id -> isCorrect
  final KppFilter filter;
  final bool isLoading;

  const KppState({
    this.allQuestions = const [],
    this.filteredQuestions = const [],
    this.progress = const {},
    this.filter = KppFilter.all,
    this.isLoading = true,
  });

  int get correctCount => progress.values.where((v) => v == true).length;
  int get incorrectCount => progress.values.where((v) => v == false).length;
  int get totalCount => allQuestions.length;

  KppState copyWith({
    List<KppQuestion>? allQuestions,
    List<KppQuestion>? filteredQuestions,
    Map<int, bool>? progress,
    KppFilter? filter,
    bool? isLoading,
  }) {
    return KppState(
      allQuestions: allQuestions ?? this.allQuestions,
      filteredQuestions: filteredQuestions ?? this.filteredQuestions,
      progress: progress ?? this.progress,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final kppRepositoryProvider = Provider<KppRepository>((ref) => KppRepository());
final kppProgressRepositoryProvider = Provider<KppProgressRepository>((ref) => KppProgressRepository());

class KppController extends Notifier<KppState> {
  late final KppRepository _repository;
  late final KppProgressRepository _progressRepository;

  @override
  KppState build() {
    _repository = ref.watch(kppRepositoryProvider);
    _progressRepository = ref.watch(kppProgressRepositoryProvider);
    
    // Initialize data
    Future.microtask(() => _init());
    
    return const KppState();
  }

  Future<void> _init() async {
    final questions = await _repository.getQuestions();
    final progress = await _progressRepository.loadProgress();
    
    state = state.copyWith(
      allQuestions: questions,
      progress: progress,
      isLoading: false,
    );
    _applyFilter();
  }

  void setFilter(KppFilter filter) {
    state = state.copyWith(filter: filter);
    _applyFilter();
  }

  void _applyFilter() {
    List<KppQuestion> filtered;
    if (state.filter == KppFilter.learning) {
      // Exclude correctly answered questions
      filtered = state.allQuestions.where((q) => state.progress[q.id] != true).toList();
    } else {
      filtered = List.from(state.allQuestions);
    }
    state = state.copyWith(filteredQuestions: filtered);
  }

  Future<void> markAnswer(int questionId, bool isCorrect) async {
    final newProgress = Map<int, bool>.from(state.progress);
    newProgress[questionId] = isCorrect;
    
    state = state.copyWith(progress: newProgress);
    await _progressRepository.saveProgress(newProgress);
  }

  Future<void> resetIncorrect() async {
    final newProgress = Map<int, bool>.from(state.progress);
    newProgress.removeWhere((key, value) => value == false);
    
    state = state.copyWith(progress: newProgress);
    await _progressRepository.saveProgress(newProgress);
    _applyFilter();
  }

  Future<void> resetAll() async {
    state = state.copyWith(progress: {});
    await _progressRepository.clearProgress();
    _applyFilter();
  }
}

final kppControllerProvider = NotifierProvider<KppController, KppState>(KppController.new);

