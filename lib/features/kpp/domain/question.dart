class KppQuestion {
  final int id;
  final String question;
  final List<String> answers;
  final int correctAnswerIndex;
  final String? explanation;

  const KppQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.correctAnswerIndex,
    this.explanation,
  });

  factory KppQuestion.fromJson(Map<String, dynamic> json) {
    return KppQuestion(
      id: json['id'] as int,
      question: json['question'] as String,
      answers: (json['answers'] as List<dynamic>).map((e) => e as String).toList(),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answers': answers,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}
