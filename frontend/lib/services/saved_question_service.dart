import 'package:dio/dio.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';

class SavedQuestionService {
  static Future<List<dynamic>> getSaved({String? subject}) async {
    String url = ApiEndpoints.savedQuestions;
    if (subject != null && subject.isNotEmpty) {
      url += '?subject=$subject';
    }
    final res = await ApiClient().dio.get(url);
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> saveQuestion({
    required String questionText,
    String? answerText,
    String? subject,
    bool isAiGenerated = true,
  }) async {
    final res = await ApiClient().dio.post(
      ApiEndpoints.savedQuestions,
      data: {
        'question_text': questionText,
        if (answerText != null) 'answer_text': answerText,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'is_ai_generated': isAiGenerated,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<void> deleteQuestion(int id) async {
    await ApiClient().dio.delete(ApiEndpoints.savedQuestionDelete(id));
  }
}
