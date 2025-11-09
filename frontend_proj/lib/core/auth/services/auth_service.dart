import 'package:dio/dio.dart';
import 'package:frontend_proj/core/auth/models/auth_tokens.dart';
import 'package:frontend_proj/core/auth/models/user_model.dart';
import 'package:frontend_proj/core/auth/services/token_storage.dart';

/// Исключения аутентификации
class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Сервис аутентификации
class AuthService {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthService(this._dio, this._tokenStorage);

  /// Регистрация нового пользователя
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Сохраняем токены
        final tokens = AuthTokens.fromJson(data['tokens']);
        await _tokenStorage.saveTokens(tokens);

        // Возвращаем пользователя
        return UserModel.fromJson(data['user']);
      }

      throw AuthException('Ошибка регистрации');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException('Пользователь с таким email уже существует');
      }
      throw AuthException(
        e.response?.data?['message'] ?? 'Ошибка регистрации',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthException('Произошла ошибка: $e');
    }
  }

  /// Вход пользователя
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signin',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Сохраняем токены
        final tokens = AuthTokens.fromJson(data['tokens']);
        await _tokenStorage.saveTokens(tokens);

        // Возвращаем пользователя
        return UserModel.fromJson(data['user']);
      }

      throw AuthException('Ошибка входа');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Неверный email или пароль');
      }
      throw AuthException(
        e.response?.data?['message'] ?? 'Ошибка входа',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw AuthException('Произошла ошибка: $e');
    }
  }

  /// Выход пользователя
  Future<void> signOut() async {
    try {
      // Отправляем запрос на сервер для инвалидации токена
      await _dio.post('/auth/signout');
    } catch (e) {
      // Игнорируем ошибки при выходе
    } finally {
      // В любом случае удаляем локальные токены
      await _tokenStorage.clearTokens();
    }
  }

  /// Обновление токена
  Future<AuthTokens> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        throw AuthException('Refresh token не найден');
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(response.data);
        await _tokenStorage.saveTokens(tokens);
        return tokens;
      }

      throw AuthException('Ошибка обновления токена');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Refresh token недействителен, нужна повторная авторизация
        await _tokenStorage.clearTokens();
        throw AuthException('Сессия истекла. Необходима повторная авторизация');
      }
      throw AuthException(
        e.response?.data?['message'] ?? 'Ошибка обновления токена',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Получить текущего пользователя
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }

      throw AuthException('Ошибка получения данных пользователя');
    } on DioException catch (e) {
      throw AuthException(
        e.response?.data?['message'] ?? 'Ошибка получения данных',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Проверить, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    final tokens = await _tokenStorage.getTokens();
    return tokens != null && tokens.isValid;
  }
}
