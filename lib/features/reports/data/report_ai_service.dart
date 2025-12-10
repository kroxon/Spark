import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:iskra/core/config/api_keys.dart';
import 'package:iskra/features/reports/data/ai_prompts_config.dart';

class ReportAiService {
  static const String _apiKey = ApiKeys.geminiApiKey; 
  late final GenerativeModel _model;

  ReportAiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(AiPromptConfig.systemInstruction),
    );
  }

  /// Generuje treść raportu na podstawie intencji użytkownika
  Future<String> generateReportFromIntent({
    required String intent,
    String? topic,
    String? currentContent,
  }) async {
    if (intent.trim().isEmpty) return currentContent ?? "";

    final prompt = '''
TEMAT: ${topic ?? "Brak"}
INTENCJA UŻYTKOWNIKA: "$intent"
OBECNA TREŚĆ (jeśli jest): "${currentContent ?? ""}"

Zadanie: Napisz lub popraw treść dokumentu zgodnie z intencją.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "";
    } catch (e) {
      throw Exception('AI generation failed: $e');
    }
  }

  /// Sugeruje temat raportu na podstawie intencji
  Future<String> suggestTopic(String intent) async {
    if (intent.trim().isEmpty) return "";
    
    final prompt = 'Zaproponuj krótki, formalny temat (tytuł) raportu dla następującej intencji: "$intent". Zwróć TYLKO temat.';
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll('"', '').trim() ?? "";
    } catch (e) {
      return "";
    }
  }

  // Deprecated: Old method kept for compatibility if needed, but redirected to new logic
  Future<String> enhanceReportText(String rawText, String reportType) async {
    return generateReportFromIntent(intent: "Popraw styl na formalny", topic: reportType, currentContent: rawText);
  }
}
