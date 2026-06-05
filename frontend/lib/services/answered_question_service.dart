import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/answered_question.dart';
import '../models/exam_model.dart';

class AnsweredQuestionService {
  static const _key = 'answered_questions';

  static Future<Map<String, List<AnsweredQuestion>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) {
      final list = (v as List).map((e) =>
          AnsweredQuestion.fromJson(e as Map<String, dynamic>)).toList();
      return MapEntry(k, list);
    });
  }

  static Future<void> save(
      Map<String, List<AnsweredQuestion>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = data.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()));
    await prefs.setString(_key, json.encode(encoded));
  }

  static Future<void> saveFromQuiz({
    required ExamModel exam,
    required Map<String, int?> answers,
    required Map<String, bool> correctness,
  }) async {
    final all = await load();

    for (final q in exam.questions) {
      final userAns = answers[q.id];
      if (userAns == null) continue;

      final subj = q.subject;
      all.putIfAbsent(subj, () => []);
      all[subj]!.add(AnsweredQuestion(
        questionId: q.id,
        examSource: exam.source,
        selectedAnswer: userAns,
        isCorrect: correctness[q.id] ?? false,
      ));
    }

    await save(all);
  }

  static Future<List<AnsweredQuestion>> forSubject(
      String subject) async {
    final all = await load();
    return all[subject] ?? [];
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
