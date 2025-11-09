import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth.dart';
import 'package:frontend_proj/core/navigation/app_navigation.dart';
import 'package:frontend_proj/core/utils/validators.dart';
import 'package:frontend_proj/features/auth/sign_in/models/sign_in_model.dart';

class SignInViewModel extends Notifier<SignInState> {
  SignInViewModel();

  AppNavigation get _navigation => ref.read(appNavigationProvider);

  @override
  SignInState build() {
    return const SignInState();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  void onEmailSubmit() {
    passwordFocusNode.requestFocus();
    checkEmail();
  }

  void resetEmail() {
    state = state.copyWith(emailError: null);
  }

  void checkEmail() {
    final errorMessage = Validators.validateEmail(emailController.text);
    debugPrint("Email error: $errorMessage");
    state = state.copyWith(emailError: errorMessage);
  }

  void onPasswordSubmit() {
    checkPassword();
    signIn();
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
    if (state.isLoading) return;
    final current = state.isPasswordVisible;
    state = state.copyWith(isPasswordVisible: !current);
  }

  Future<void> signIn() async {
    checkEmail();
    checkPassword();

    if (state.isLoading) return;
    if (!state.hasErrors) {
      state = state.copyWith(isLoading: true);

      try {
        // Используем AuthNotifier для входа
        final authNotifier = ref.read(authNotifierProvider.notifier);
        await authNotifier.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // После успешного входа переходим на главную
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

  void goToSignUp() {
    _navigation.goToSignUp();
  }
}
