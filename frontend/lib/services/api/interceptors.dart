import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Set Content-Type only for JSON requests, not multipart (images/voice)
    final hasFile = options.data is FormData;
    if (!hasFile && !options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.refresh}',
            data: {'refresh': refreshToken},
          );
          final newAccess = response.data['access'];
          await TokenStorage.saveTokens(
            access: newAccess,
            refresh: refreshToken,
          );
          final retryOpts = err.requestOptions;
          retryOpts.headers['Authorization'] = 'Bearer $newAccess';
          final retryResponse = await Dio().fetch(retryOpts);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          await TokenStorage.clearTokens();
        }
      }
    }
    handler.next(err);
  }
}
