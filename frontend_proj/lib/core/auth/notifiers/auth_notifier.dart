import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/auth/models/auth_state.dart';
import 'package:frontend_proj/core/auth/models/user_model.dart';
import 'package:frontend_proj/core/auth/services/auth_service.dart';

/// Notifier для управления состоянием аутентификации
class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _checkAuth();
    return const AuthState.initial();
  }

  /// Проверка авторизации при запуске
  Future<void> _checkAuth() async {
    try {
      state = const AuthState.loading();
      final isAuth = await _authService.isAuthenticated();

      if (isAuth) {
        final user = await _authService.getCurrentUser();
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Регистрация
  Future<void> signUp({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      final user = await _authService.signUp(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = const AuthState.unauthenticated();
      rethrow;
    }
  }

  /// Вход
  Future<void> signIn({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      final user = await _authService.signIn(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = const AuthState.unauthenticated();
      rethrow;
    }
  }

  /// Выход
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      // Даже при ошибке выходим
      state = const AuthState.unauthenticated();
    }
  }

  /// Обновить данные пользователя
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      // Если не удалось обновить, считаем что не авторизован
      state = const AuthState.unauthenticated();
    }
  }

  /// Получить текущего пользователя
  UserModel? get currentUser =>
      state.maybeMap(authenticated: (state) => state.user, orElse: () => null);

  /// Проверить авторизацию
  bool get isAuthenticated =>
      state.maybeMap(authenticated: (_) => true, orElse: () => false);
}
