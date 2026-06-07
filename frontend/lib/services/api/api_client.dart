import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'interceptors.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      // Content-Type auto-detected: JSON for regular requests,
      // multipart/form-data when sending files (images/voice)
    ));
    dio.interceptors.add(AuthInterceptor());
  }
}
