import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'api/api_endpoints.dart';
import 'api/token_storage.dart';

class AuthService {
  static const _currentUserKey = 'current_username';
  static const _userIdKey = 'current_user_id';
  static const _activatedKey = 'is_activated';
  static const _roleKey = 'user_role';

  static Future<String?> register(String username, String password) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.register, data: {
        'username': username,
        'password': password,
      });
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  static Future<String?> login(String username, String password) async {
    try {
      final response = await ApiClient().dio.post(ApiEndpoints.login, data: {
        'username': username,
        'password': password,
      });
      final data = response.data;
      await TokenStorage.saveTokens(
        access: data['access'],
        refresh: data['refresh'],
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, data['user']['username']);
      await prefs.setInt(_userIdKey, data['user']['id']);
      await prefs.setBool(
        _activatedKey,
        data['user']['is_activated'] ?? false,
      );
      await prefs.setString(
        _roleKey,
        data['user']['role'] ?? 'student',
      );
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  static Future<String?> activate(String code) async {
    try {
      await ApiClient().dio.post(ApiEndpoints.activate, data: {'code': code});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_activatedKey, true);
      return null;
    } on DioException catch (e) {
      return _extractError(e);
    }
  }

  static Future<Map<String, dynamic>?> getSession() async {
    try {
      final response = await ApiClient().dio.get(ApiEndpoints.profile);
      final data = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, data['username']);
      await prefs.setInt(_userIdKey, data['id']);
      await prefs.setBool(_activatedKey, data['is_activated'] ?? false);
      await prefs.setString(_roleKey, data['role'] ?? 'student');
      return {
        'id': data['id'],
        'username': data['username'],
        'is_activated': data['is_activated'] ?? false,
        'role': data['role'] ?? 'student',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<bool> isActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activatedKey) ?? false;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'student';
  }

  static Future<List<Map<String, dynamic>>?> generateCodes(int count) async {
    try {
      final response = await ApiClient().dio.post(
        ApiEndpoints.adminCodesGenerate,
        data: {'count': count},
      );
      return List<Map<String, dynamic>>.from(response.data['codes']);
    } on DioException {
      return null;
    }
  }

  static Future<void> logout() async {
    await TokenStorage.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_activatedKey);
    await prefs.remove(_roleKey);
  }

  static String _extractError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['detail'] != null) return data['detail'].toString();
      if (data['code'] != null) {
        if (data['code'] is List) {
          return (data['code'] as List).first.toString();
        }
        return data['code'].toString();
      }
      if (data['username'] != null) {
        if (data['username'] is List) {
          return (data['username'] as List).first.toString();
        }
        return data['username'].toString();
      }
      if (data['password'] != null) {
        if (data['password'] is List) {
          return (data['password'] as List).first.toString();
        }
        return data['password'].toString();
      }
      if (data['non_field_errors'] != null) {
        if (data['non_field_errors'] is List) {
          return (data['non_field_errors'] as List).first.toString();
        }
        return data['non_field_errors'].toString();
      }
    }
    if (e.response?.statusCode == 400) return 'Invalid data';
    if (e.response?.statusCode == 401) return 'Invalid credentials';
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    }
    return 'An error occurred';
  }
}
