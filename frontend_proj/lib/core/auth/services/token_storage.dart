import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_proj/core/auth/models/auth_tokens.dart';

/// Сервис для безопасного хранения токенов
class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';

  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  /// Сохранить токены
  Future<void> saveTokens(AuthTokens tokens) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: tokens.accessToken),
      _storage.write(key: _refreshTokenKey, value: tokens.refreshToken),
      _storage.write(
        key: _expiresAtKey,
        value: tokens.expiresAt.toIso8601String(),
      ),
    ]);
  }

  /// Получить токены
  Future<AuthTokens?> getTokens() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _accessTokenKey),
        _storage.read(key: _refreshTokenKey),
        _storage.read(key: _expiresAtKey),
      ]);

      final accessToken = values[0];
      final refreshToken = values[1];
      final expiresAtStr = values[2];

      if (accessToken == null || refreshToken == null || expiresAtStr == null) {
        return null;
      }

      return AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: DateTime.parse(expiresAtStr),
      );
    } catch (e) {
      return null;
    }
  }

  /// Удалить токены
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }

  /// Получить access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Получить refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Проверить наличие токенов
  Future<bool> hasTokens() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null;
  }
}
