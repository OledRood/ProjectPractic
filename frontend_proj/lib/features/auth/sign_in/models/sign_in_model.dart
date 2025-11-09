import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_model.freezed.dart';

@freezed
sealed class SignInState with _$SignInState {
  const SignInState._();

  const factory SignInState({
    String? emailError,
    String? passwordError,
    @Default(false) bool isPasswordVisible,
    @Default(false) bool isLoading,
  }) = _SignInState;

  bool get hasErrors => emailError != null || passwordError != null;
}
