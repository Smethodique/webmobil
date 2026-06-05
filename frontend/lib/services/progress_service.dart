import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_model.dart';

class ProgressService {
  static const _subjectKey = 'subject_progress';
  static const _examKey = 'exam_progress';

  static Future<Map<String, Map<String, int>>> loadSubjectProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_subjectKey);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) {
      final m = v as Map<String, dynamic>;
      return MapEntry(k, {
        'correct': m['correct'] as int? ?? 0,
        'wrong': m['wrong'] as int? ?? 0,
      });
    });
  }

  static Future<Map<String, Map<String, int>>> loadExamProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_examKey);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) {
      final m = v as Map<String, dynamic>;
      return MapEntry(k, {
        'correct': m['correct'] as int? ?? 0,
        'wrong': m['wrong'] as int? ?? 0,
      });
    });
  }

  static Future<void> saveSubjectProgress(
      Map<String, Map<String, int>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subjectKey, json.encode(data));
  }

  static Future<void> saveExamProgress(
      Map<String, Map<String, int>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_examKey, json.encode(data));
  }

  static Future<void> updateFromQuiz({
    required ExamModel exam,
    required Map<String, int?> answers,
    required Map<String, bool> correctness,
  }) async {
    final subjectProgress = await loadSubjectProgress();
    final examProgress = await loadExamProgress();

    for (final q in exam.questions) {
      final userAns = answers[q.id];
      if (userAns == null) continue;

      final subj = q.subject;
      subjectProgress.putIfAbsent(subj, () => {'correct': 0, 'wrong': 0});
      if (correctness[q.id] == true) {
        subjectProgress[subj]!['correct'] =
            subjectProgress[subj]!['correct']! + 1;
      } else {
        subjectProgress[subj]!['wrong'] =
            subjectProgress[subj]!['wrong']! + 1;
      }

      examProgress.putIfAbsent(exam.source, () => {'correct': 0, 'wrong': 0});
      if (correctness[q.id] == true) {
        examProgress[exam.source]!['correct'] =
            examProgress[exam.source]!['correct']! + 1;
      } else {
        examProgress[exam.source]!['wrong'] =
            examProgress[exam.source]!['wrong']! + 1;
      }
    }

    await saveSubjectProgress(subjectProgress);
    await saveExamProgress(examProgress);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subjectKey);
    await prefs.remove(_examKey);
  }

  static Map<String, int> computeTotalQuestions(List<ExamModel> allExams) {
    final totals = <String, int>{};
    for (final exam in allExams) {
      for (final q in exam.questions) {
        totals[q.subject] = (totals[q.subject] ?? 0) + 1;
      }
    }
    return totals;
  }

  static List<String> extractAllSubjects(List<ExamModel> allExams) {
    final set = <String>{};
    for (final exam in allExams) {
      for (final q in exam.questions) {
        set.add(q.subject);
      }
    }
    return set.toList()..sort();
  }

  static List<ExamModel> examsForSubject(
      List<ExamModel> allExams, String subject) {
    return allExams
        .where((e) => e.questions.any((q) => q.subject == subject))
        .toList();
  }

  static int countQuestionsForSubject(ExamModel exam, String subject) {
    return exam.questions.where((q) => q.subject == subject).length;
  }
}
