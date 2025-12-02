import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/fitness/data/fitness_repository.dart';
import 'package:iskra/features/fitness/domain/fitness_test.dart';

final fitnessControllerProvider = AsyncNotifierProvider<FitnessController, List<FitnessTest>>(FitnessController.new);

class FitnessController extends AsyncNotifier<List<FitnessTest>> {
  @override
  FutureOr<List<FitnessTest>> build() async {
    final repository = ref.watch(fitnessRepositoryProvider);
    return repository.getTests();
  }

  Future<void> addTest(FitnessTest test) async {
    final repository = ref.read(fitnessRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.saveTest(test);
      return repository.getTests();
    });
  }

  Future<void> deleteTest(String id) async {
    final repository = ref.read(fitnessRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTest(id);
      return repository.getTests();
    });
  }
}
