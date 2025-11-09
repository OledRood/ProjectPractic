import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_proj/core/auth/models/auth_state.dart';
import 'package:frontend_proj/core/auth/notifiers/auth_notifier.dart';
import 'package:frontend_proj/core/auth/services/auth_service.dart';
import 'package:frontend_proj/core/auth/services/token_storage.dart';

/// Provider для FlutterSecureStorage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Provider для TokenStorage
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorage(storage);
});

/// Provider для Dio
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://your-api-url.com/api', // Замените на ваш API URL
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Добавляем interceptor для автоматического добавления токена
  dio.interceptors.add(AuthInterceptor(ref));

  return dio;
});

/// Provider для AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthService(dio, tokenStorage);
});

/// Provider для AuthNotifier
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Interceptor для добавления токена к запросам
class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final accessToken = await tokenStorage.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Если получили 401, пытаемся обновить токен
    if (err.response?.statusCode == 401) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.refreshToken();

        // Повторяем запрос с новым токеном
        final options = err.requestOptions;
        final tokenStorage = ref.read(tokenStorageProvider);
        final newToken = await tokenStorage.getAccessToken();

        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
          final dio = ref.read(dioProvider);
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // Если не удалось обновить токен, разлогиниваем
        final authNotifier = ref.read(authNotifierProvider.notifier);
        await authNotifier.signOut();
      }
    }

    handler.next(err);
  }
}
