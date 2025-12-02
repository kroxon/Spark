import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iskra/features/fitness/domain/fitness_test.dart';

final fitnessRepositoryProvider = Provider<FitnessRepository>((ref) {
  return FitnessRepository();
});

class FitnessRepository {
  static const String _storageKey = 'fitness_tests';

  Future<List<FitnessTest>> getTests() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => FitnessTest.fromJson(json)).toList();
  }

  Future<void> saveTest(FitnessTest test) async {
    final prefs = await SharedPreferences.getInstance();
    final List<FitnessTest> currentTests = await getTests();
    
    // Add new test to the beginning of the list
    currentTests.insert(0, test);
    
    final String jsonString = json.encode(currentTests.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> deleteTest(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<FitnessTest> currentTests = await getTests();
    
    currentTests.removeWhere((t) => t.id == id);
    
    final String jsonString = json.encode(currentTests.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
