import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> init() => dotenv.load();

  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl.endsWith('/')
          ? envUrl.substring(0, envUrl.length - 1)
          : envUrl;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:8000/api/v1';
    }
    return 'http://10.0.2.2:8000/api/v1';
  }
}
