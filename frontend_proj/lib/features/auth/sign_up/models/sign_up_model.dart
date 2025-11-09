import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_up_model.freezed.dart';

@freezed
sealed class SignUpState with _$SignUpState {
  const SignUpState._();

  const factory SignUpState({
    @Default(false) bool checkPolitics,

    String? emailError,
    String? passwordError,
    String? checkPoliticsError,
    String? confirmPasswordError,

    @Default(false) bool isPasswordVisible,
    @Default(false) bool isConfirmPasswordVisible,

    @Default(false) bool isLoading,
  }) = _SignUpState;

  bool get hasErrors =>
      emailError != null ||
      passwordError != null ||
      confirmPasswordError != null ||
      checkPoliticsError != null;
}
