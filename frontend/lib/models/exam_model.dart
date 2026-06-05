import 'question_model.dart';

class ExamModel {
  final String source;
  final List<QuestionModel> questions;

  const ExamModel({
    required this.source,
    required this.questions,
  });

  String get title {
    final parts = source
        .replaceAll('math_exemple-concours-fmp-', '')
        .replaceAll('NNN', '')
        .replaceAll('NNvN', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    final words = parts.split(' ');
    if (words.length >= 2) {
      final city = words[0];
      final year = words.last;
      return 'FMP ${city[0].toUpperCase() + city.substring(1)} $year';
    }
    return source;
  }

  int get totalQuestions => questions.length;

  List<String> get subjects {
    final set = <String>{};
    for (final q in questions) {
      set.add(q.subject);
    }
    return set.toList()..sort();
  }

  factory ExamModel.fromJsonList(List<dynamic> jsonList) {
    final questions = jsonList
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final source = questions.isNotEmpty
        ? questions.first.source
        : 'unknown';
    return ExamModel(source: source, questions: questions);
  }
}
