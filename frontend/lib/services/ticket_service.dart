import 'package:dio/dio.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';

class TicketService {
  static Future<List<dynamic>> getTickets() async {
    final res = await ApiClient().dio.get(ApiEndpoints.tickets);
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createTicket({
    required String questionText,
    String? exerciseReference,
    String? examTitle,
    String? screenshotPath,
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('question_text', questionText));
    if (exerciseReference != null && exerciseReference.isNotEmpty) {
      form.fields.add(MapEntry('exercise_reference', exerciseReference));
    }
    if (examTitle != null && examTitle.isNotEmpty) {
      form.fields.add(MapEntry('exam_title', examTitle));
    }
    if (screenshotPath != null) {
      form.files.add(MapEntry(
        'screenshot', await MultipartFile.fromFile(screenshotPath),
      ));
    }
    final res = await ApiClient().dio.post(
      ApiEndpoints.ticketsCreate,
      data: form,
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> replyToTicket({
    required int ticketId,
    String? responseText,
    String? responseImagePath,
  }) async {
    final form = FormData();
    if (responseText != null && responseText.isNotEmpty) {
      form.fields.add(MapEntry('response_text', responseText));
    }
    if (responseImagePath != null) {
      form.files.add(MapEntry(
        'response_image', await MultipartFile.fromFile(responseImagePath),
      ));
    }
    final res = await ApiClient().dio.post(
      ApiEndpoints.ticketsReply(ticketId),
      data: form,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return res.data as Map<String, dynamic>;
  }
}
