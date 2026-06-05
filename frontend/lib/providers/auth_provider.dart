import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? error;
  final bool isActivated;
  final String role;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.error,
    this.isActivated = false,
    this.role = 'student',
  });

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? error,
    bool? isActivated,
    String? role,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      error: error,
      isActivated: isActivated ?? this.isActivated,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await AuthService.getSession();
    if (session != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        username: session['username'],
        isActivated: session['is_activated'] ?? false,
        role: session['role'] ?? 'student',
      );
    } else {
      await AuthService.logout();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<String?> register(String username, String password) async {
    state = state.copyWith(error: null);
    final err = await AuthService.register(username, password);
    if (err != null) {
      state = state.copyWith(error: err);
      return err;
    }
    return null;
  }

  Future<String?> login(String username, String password) async {
    state = state.copyWith(error: null);
    final err = await AuthService.login(username, password);
    if (err != null) {
      state = state.copyWith(error: err);
      return err;
    }
    final prefs = await SharedPreferences.getInstance();
    final isActivated = prefs.getBool('is_activated') ?? false;
    final role = prefs.getString('user_role') ?? 'student';
    state = AuthState(
      status: AuthStatus.authenticated,
      username: username,
      isActivated: isActivated,
      role: role,
    );
    return null;
  }

  Future<String?> activate(String code) async {
    state = state.copyWith(error: null);
    final err = await AuthService.activate(code);
    if (err != null) {
      state = state.copyWith(error: err);
      return err;
    }
    state = state.copyWith(isActivated: true);
    return null;
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
