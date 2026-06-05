class AnsweredQuestion {
  final String questionId;
  final String examSource;
  final int selectedAnswer;
  final bool isCorrect;

  const AnsweredQuestion({
    required this.questionId,
    required this.examSource,
    required this.selectedAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'qId': questionId,
        'exam': examSource,
        'ans': selectedAnswer,
        'correct': isCorrect,
      };

  factory AnsweredQuestion.fromJson(Map<String, dynamic> json) {
    return AnsweredQuestion(
      questionId: json['qId'] as String,
      examSource: json['exam'] as String,
      selectedAnswer: json['ans'] as int,
      isCorrect: json['correct'] as bool,
    );
  }
}
