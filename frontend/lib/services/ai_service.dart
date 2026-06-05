import 'package:dio/dio.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';

class AiService {
  static Future<String> solveQuestion({
    required String question,
    String? subject,
    List<String>? choices,
  }) async {
    final res = await ApiClient().dio.post(
      ApiEndpoints.aiSolve,
      data: {
        'question': question,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (choices != null && choices.isNotEmpty) 'choices': choices,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return res.data['result'] as String;
  }

  static Future<String> generateSimilar({
    required String question,
    String? subject,
  }) async {
    final res = await ApiClient().dio.post(
      ApiEndpoints.aiSimilar,
      data: {
        'question': question,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
      },
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return res.data['result'] as String;
  }

  static Future<String> aiChat({required String text}) async {
    final res = await ApiClient().dio.post(
      ApiEndpoints.aiChat,
      data: {'text': text},
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return res.data['result'] as String;
  }

  static Future<String?> ocrImage({required String imagePath}) async {
    final form = FormData();
    form.files.add(MapEntry(
      'image', await MultipartFile.fromFile(imagePath),
    ));
    final res = await ApiClient().dio.post(
      ApiEndpoints.aiOcr,
      data: form,
      options: Options(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return res.data['text'] as String?;
  }
}
