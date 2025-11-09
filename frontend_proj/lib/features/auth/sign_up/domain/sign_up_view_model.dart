import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth.dart';
import 'package:frontend_proj/core/navigation/app_navigation.dart';
import 'package:frontend_proj/features/auth/sign_up/models/sign_up_model.dart';

import '../../../../core/utils/validators.dart';

class SignUpViewModel extends Notifier<SignUpState> {
  SignUpViewModel();

  AppNavigation get _navigation => ref.read(appNavigationProvider);
  @override
  SignUpState build() {
    return SignUpState();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  void onEmailSubmit() {
    passwordFocusNode.requestFocus();
    checkEmail();
  }

  void resetEmail() {
    state = state.copyWith(emailError: null);
  }

  void checkEmail() {
    final errorMassage = Validators.validateEmail(emailController.text);
    debugPrint("Email error: $errorMassage");
    state = state.copyWith(emailError: errorMassage);
  }

  void onPasswordSubmit() {
    checkPassword();
    confirmPasswordFocusNode.requestFocus();
  }

  void goToHome() {
    _navigation.goToGetVideo();
  }

  void resetPassword(String _) {
    state = state.copyWith(passwordError: null);
  }

  void checkPassword() {
    final errorMessage = Validators.validatePassword(passwordController.text);
    debugPrint("Password error: $errorMessage");
    state = state.copyWith(passwordError: errorMessage);
  }

  void changePasswordVisibility() {
    final current = state.isPasswordVisible;
    state = state.copyWith(isPasswordVisible: !current);
  }

  void onConfirmPasswordSubmit() {
    checkConfirmPassword();
    create();
  }

  void resetConfirmPassword(String _) {
    if (state.isLoading) return;
    state = state.copyWith(confirmPasswordError: null);
  }

  void checkConfirmPassword() {
    final errorMessage = Validators.validateConfirmPassword(
      passwordController.text,
      confirmPasswordController.text,
    );
    debugPrint("Confirm Password error: $errorMessage");
    state = state.copyWith(confirmPasswordError: errorMessage);
  }

  void changeConfirmPasswordVisible() {
    if (state.isLoading) return;
    final current = state.isConfirmPasswordVisible;
    state = state.copyWith(isConfirmPasswordVisible: !current);
  }

  void updateCheckPolitics(bool newValue) {
    if (state.isLoading) return;
    state = state.copyWith(checkPolitics: newValue);
    state = state.copyWith(checkPoliticsError: null);
  }

  void checkPolitics() {
    if (!state.checkPolitics) {
      state = state.copyWith(
        checkPoliticsError: "Необходимо принять соглашение",
      );
    }
  }

  Future<void> create() async {
    checkEmail();
    checkPassword();
    checkConfirmPassword();
    checkPolitics();
    if (state.isLoading) return;
    if (!state.hasErrors) {
      state = state.copyWith(isLoading: true);

      try {
        // Используем AuthNotifier для регистрации
        final authNotifier = ref.read(authNotifierProvider.notifier);
        await authNotifier.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // После успешной регистрации переходим на главную
        _navigation.goToGetVideo();
      } on AuthException catch (e) {
        // Показываем ошибку пользователю
        debugPrint("Auth error: ${e.message}");
        state = state.copyWith(emailError: e.message, isLoading: false);
      } catch (e) {
        debugPrint("Unknown error: $e");
        state = state.copyWith(
          emailError: "Произошла ошибка. Попробуйте еще раз",
          isLoading: false,
        );
      }
    }
  }

  void goBack() {
    _navigation.goBack();
  }
}
