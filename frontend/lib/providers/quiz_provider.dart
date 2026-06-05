import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/result_model.dart';
import '../services/answered_question_service.dart';
import '../services/progress_service.dart';

class QuizState {
  final ExamModel exam;
  final ResultModel? result;
  final int currentIndex;
  final Map<String, int?> answers;
  final Set<String> bookmarked;
  final bool submitted;
  final DateTime startTime;
  final int? endTimeSeconds;
  final Map<String, bool> correctness;
  final int correctCount;

  const QuizState({
    required this.exam,
    this.result,
    this.currentIndex = 0,
    this.answers = const {},
    this.bookmarked = const {},
    this.submitted = false,
    required this.startTime,
    this.endTimeSeconds,
    this.correctness = const {},
    this.correctCount = 0,
  });

  QuizState copyWith({
    int? currentIndex,
    Map<String, int?>? answers,
    Set<String>? bookmarked,
    bool? submitted,
    DateTime? startTime,
    int? endTimeSeconds,
    ResultModel? result,
    Map<String, bool>? correctness,
    int? correctCount,
  }) {
    return QuizState(
      exam: exam,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      bookmarked: bookmarked ?? this.bookmarked,
      submitted: submitted ?? this.submitted,
      startTime: startTime ?? this.startTime,
      endTimeSeconds: endTimeSeconds,
      result: result ?? this.result,
      correctness: correctness ?? this.correctness,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  QuestionModel get currentQuestion => exam.questions[currentIndex];

  int get answeredCount => answers.values.where((a) => a != null).length;

  int get unansweredCount => exam.questions.length - answeredCount;

  int get bookmarkedCount => bookmarked.length;

  double get progress => exam.questions.isEmpty
      ? 0
      : answeredCount / exam.questions.length;

  int get elapsedSeconds =>
      DateTime.now().difference(startTime).inSeconds;

  bool isCorrect(String questionId) {
    return correctness[questionId] ?? false;
  }

  bool? correctnessFor(String questionId) {
    return correctness[questionId];
  }

  int get gradedCount => exam.questions.length;
}

class QuizNotifier extends StateNotifier<QuizState?> {
  QuizNotifier() : super(null);

  void startExam(ExamModel exam, {ResultModel? result}) {
    state = QuizState(
      exam: exam,
      result: result,
      startTime: DateTime.now(),
    );
  }

  void goToQuestion(int index) {
    if (state == null) return;
    final clamped = index.clamp(0, state!.exam.questions.length - 1);
    state = state!.copyWith(currentIndex: clamped);
  }

  void answer(String questionId, int optionIndex) {
    if (state == null || state!.submitted) return;
    final updated = Map<String, int?>.from(state!.answers)
      ..[questionId] = optionIndex;
    state = state!.copyWith(answers: updated);
  }

  void toggleBookmark(String questionId) {
    if (state == null || state!.submitted) return;
    final updated = Set<String>.from(state!.bookmarked);
    if (updated.contains(questionId)) {
      updated.remove(questionId);
    } else {
      updated.add(questionId);
    }
    state = state!.copyWith(bookmarked: updated);
  }

  Future<void> submit() async {
    if (state == null) return;

    final s = state!;
    final result = s.result;
    final correctness = <String, bool>{};
    var correctCount = 0;

    for (final q in s.exam.questions) {
      final userAns = s.answers[q.id];
      if (userAns == null) {
        correctness[q.id] = false;
        continue;
      }
      if (result != null && result.isCorrect(q.id, userAns)) {
        correctness[q.id] = true;
        correctCount++;
      } else {
        correctness[q.id] = false;
      }
    }

    state = s.copyWith(
      submitted: true,
      endTimeSeconds: s.elapsedSeconds,
      correctness: correctness,
      correctCount: correctCount,
    );

    await ProgressService.updateFromQuiz(
      exam: s.exam,
      answers: s.answers,
      correctness: correctness,
    );
    await AnsweredQuestionService.saveFromQuiz(
      exam: s.exam,
      answers: s.answers,
      correctness: correctness,
    );
  }

  void reset() {
    state = null;
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState?>((ref) {
  return QuizNotifier();
});
