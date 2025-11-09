import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/auth/models/auth_state.dart';
import 'package:frontend_proj/core/auth/models/user_model.dart';
import 'package:frontend_proj/core/auth/services/auth_service.dart';

/// ============================================================================
/// 🔧 РЕЖИМ ЗАГЛУШЕК АКТИВЕН
/// ============================================================================
/// Аутентификация работает с mock-данными без реальных запросов к серверу.
/// Любой email/password будет принят, и пользователь автоматически войдет.
///
/// Для активации реальной аутентификации:
/// 1. Раскомментируйте блоки кода с меткой "📝 Закомментировано для продакшена"
/// 2. Удалите блоки кода с меткой "🔧 ЗАГЛУШКА"
/// ============================================================================

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

      // 🔧 ЗАГЛУШКА: Автоматически считаем пользователя авторизованным
      await Future.delayed(const Duration(milliseconds: 100));
      final mockUser = UserModel(
        id: 'mock-user-123',
        email: 'mock@example.com',
        name: 'Mock User',
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
      state = AuthState.authenticated(mockUser);

      // 📝 Закомментировано для продакшена:
      // final isAuth = await _authService.isAuthenticated();
      // if (isAuth) {
      //   final user = await _authService.getCurrentUser();
      //   state = AuthState.authenticated(user);
      // } else {
      //   state = const AuthState.unauthenticated();
      // }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Регистрация
  Future<void> signUp({required String email, required String password}) async {
    try {
      state = const AuthState.loading();

      // 🔧 ЗАГЛУШКА: Всегда успешная регистрация
      await Future.delayed(const Duration(milliseconds: 500));
      final mockUser = UserModel(
        id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: email.split('@').first,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
      state = AuthState.authenticated(mockUser);

      // 📝 Закомментировано для продакшена:
      // final user = await _authService.signUp(email: email, password: password);
      // state = AuthState.authenticated(user);
    } catch (e) {
      state = const AuthState.unauthenticated();
      rethrow;
    }
  }

  /// Вход
  Future<void> signIn({required String email, required String password}) async {
    try {
      state = const AuthState.loading();

      // 🔧 ЗАГЛУШКА: Всегда успешный вход
      await Future.delayed(const Duration(milliseconds: 500));
      final mockUser = UserModel(
        id: 'mock-user-${email.hashCode}',
        email: email,
        name: email.split('@').first,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
      state = AuthState.authenticated(mockUser);

      // 📝 Закомментировано для продакшена:
      // final user = await _authService.signIn(email: email, password: password);
      // state = AuthState.authenticated(user);
    } catch (e) {
      state = const AuthState.unauthenticated();
      rethrow;
    }
  }

  /// Выход
  Future<void> signOut() async {
    try {
      // 🔧 ЗАГЛУШКА: Просто очищаем состояние без реального запроса
      await Future.delayed(const Duration(milliseconds: 200));
      state = const AuthState.unauthenticated();

      // 📝 Закомментировано для продакшена:
      // await _authService.signOut();
      // state = const AuthState.unauthenticated();
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
