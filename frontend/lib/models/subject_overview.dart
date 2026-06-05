import 'exam_model.dart';

class SubjectOverview {
  final String name;
  final int correct;
  final int wrong;
  final int totalQuestions;
  final List<ExamWithSubjectCount> exams;

  SubjectOverview({
    required this.name,
    this.correct = 0,
    this.wrong = 0,
    this.totalQuestions = 0,
    this.exams = const [],
  });

  int get answered => correct + wrong;
  int get unanswered => totalQuestions - answered;
  double get taux => totalQuestions > 0 ? correct / totalQuestions : 0;

  SubjectOverview copyWith({
    String? name,
    int? correct,
    int? wrong,
    int? totalQuestions,
    List<ExamWithSubjectCount>? exams,
  }) {
    return SubjectOverview(
      name: name ?? this.name,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      exams: exams ?? this.exams,
    );
  }
}

class ExamWithSubjectCount {
  final ExamModel exam;
  final int questionCount;
  final int? answered;
  final int? correct;

  const ExamWithSubjectCount({
    required this.exam,
    required this.questionCount,
    this.answered,
    this.correct,
  });

  double get taux =>
      answered != null && answered! > 0 ? (correct ?? 0) / answered! : 0;
}
