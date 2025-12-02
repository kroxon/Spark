import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:iskra/features/kpp/domain/question.dart';

class KppRepository {
  Future<List<KppQuestion>> getQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/data/kpp_questions.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => KppQuestion.fromJson(json)).toList();
    } catch (e) {
      // Fallback or error handling
      print('Error loading KPP questions: $e');
      return [];
    }
  }
}
