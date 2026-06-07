import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';

class ChatService {
  static Future<List<dynamic>> getGroups() async {
    final res = await ApiClient().dio.get(ApiEndpoints.chatGroups);
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> autoJoin({String groupName = 'Général'}) async {
    final res = await ApiClient().dio.post(
      ApiEndpoints.chatAutoJoin,
      data: {'group_name': groupName},
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMessages(int groupId) async {
    final res = await ApiClient().dio.get(
      ApiEndpoints.chatMessages(groupId),
    );
    return res.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int groupId,
    String? text,
    String? imagePath,
    String? voicePath,
    List<int>? voiceBytes,
    String voiceExtension = '.m4a',
    List<int>? imageBytes,
  }) async {
    final form = FormData();
    if (text != null && text.isNotEmpty) {
      form.fields.add(MapEntry('text', text));
    }
    if (imagePath != null) {
      form.files.add(MapEntry(
        'image', await MultipartFile.fromFile(imagePath),
      ));
    }
    if (voiceBytes != null && voiceBytes.isNotEmpty) {
      // ignore: deprecated_member_use
      final voiceFile = MultipartFile(
        Stream.fromIterable([Uint8List.fromList(voiceBytes)]),
        voiceBytes.length,
        filename: 'voice_${DateTime.now().millisecondsSinceEpoch}$voiceExtension',
      );
      form.files.add(MapEntry('voice', voiceFile));
    } else if (voicePath != null && voicePath.isNotEmpty) {
      form.files.add(MapEntry(
        'voice', await MultipartFile.fromFile(voicePath, filename: voicePath.split('/').last),
      ));
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      // Web: use bytes (blob URLs can't use fromFile)
      form.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(
          imageBytes,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
    }
    final res = await ApiClient().dio.post(
      ApiEndpoints.chatSend(groupId),
      data: form,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return res.data as Map<String, dynamic>;
  }
}
