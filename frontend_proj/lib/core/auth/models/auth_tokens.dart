import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

@freezed
sealed class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  const AuthTokens._();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isExpired && accessToken.isNotEmpty;
}
