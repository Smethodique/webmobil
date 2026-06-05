class ResultModel {
  final String source;
  final Map<String, Set<int>> correctAnswers;

  const ResultModel({
    required this.source,
    required this.correctAnswers,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String;
    final answersList = json['answers'] as List<dynamic>;
    final correctAnswers = <String, Set<int>>{};

    for (final entry in answersList) {
      final id = entry['id'] as String;
      final selectedIndex = entry['selectedIndex'];
      if (selectedIndex == null) continue;

      if (selectedIndex is int) {
        correctAnswers[id] = {selectedIndex};
      } else if (selectedIndex is List) {
        final set = <int>{};
        for (final idx in selectedIndex) {
          if (idx is int) set.add(idx);
        }
        if (set.isNotEmpty) correctAnswers[id] = set;
      }
    }

    return ResultModel(source: source, correctAnswers: correctAnswers);
  }

  Set<int>? correctFor(String questionId) => correctAnswers[questionId];

  bool isCorrect(String questionId, int userAnswer) {
    final answers = correctAnswers[questionId];
    if (answers == null) return false;
    return answers.contains(userAnswer);
  }
}
