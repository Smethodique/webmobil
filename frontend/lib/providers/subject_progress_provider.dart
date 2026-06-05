import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_overview.dart';
import '../services/progress_service.dart';
import 'exam_provider.dart';

final subjectProgressRefreshProvider = StateProvider<int>((ref) => 0);

final subjectOverviewProvider =
    FutureProvider<Map<String, SubjectOverview>>((ref) async {
  ref.watch(subjectProgressRefreshProvider);
  final allExams = await ref.watch(examsProvider.future);
  final rawProgress = await ProgressService.loadSubjectProgress();
  final totals = ProgressService.computeTotalQuestions(allExams);
  final subjects = ProgressService.extractAllSubjects(allExams);

  final result = <String, SubjectOverview>{};
  for (final name in subjects) {
    final p = rawProgress[name] ?? {'correct': 0, 'wrong': 0};
    final overview = SubjectOverview(
      name: name,
      correct: p['correct'] ?? 0,
      wrong: p['wrong'] ?? 0,
      totalQuestions: totals[name] ?? 0,
    );
    result[name] = overview;
  }
  return result;
});

final subjectExamsProvider =
    FutureProvider.family<List<ExamWithSubjectCount>, String>(
        (ref, subject) async {
  final allExams = await ref.watch(examsProvider.future);
  final rawExamProgress = await ProgressService.loadExamProgress();

  final matching = ProgressService.examsForSubject(allExams, subject);
  return matching.map((exam) {
    final count = ProgressService.countQuestionsForSubject(exam, subject);
    final ep = rawExamProgress[exam.source] ?? {'correct': 0, 'wrong': 0};
    final answered = (ep['correct'] ?? 0) + (ep['wrong'] ?? 0);
    return ExamWithSubjectCount(
      exam: exam,
      questionCount: count,
      answered: answered,
      correct: ep['correct'],
    );
  }).toList();
});
