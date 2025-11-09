import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/auth/sign_up/auth_di.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: _SignUpPageBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 480,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _SignUpHeader(),
                    const SizedBox(height: 40),
                    _SignUpFormCard(isMobile: isMobile),
                    const SizedBox(height: 24),
                    const _SignInLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Фон страницы с градиентом
class _SignUpPageBackground extends StatelessWidget {
  final Widget child;

  const _SignUpPageBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
          ],
        ),
      ),
      child: child,
    );
  }
}

// Заголовок с иконкой
class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Создать аккаунт',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// Карточка с формой
class _SignUpFormCard extends ConsumerWidget {
  final bool isMobile;

  const _SignUpFormCard({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(AuthDi.signUpViewmodelProvider.notifier);
    final state = ref.watch(AuthDi.signUpViewmodelProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignUpTextField(
                label: 'Электронная почта',
                hint: 'example@email.com',
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                enabled: !state.isLoading,
                errorText: state.emailError,
                onChanged: (_) => viewModel.resetEmail(),
                onSubmitted: () => viewModel.onEmailSubmit(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Zа-яА-ЯёЁ0-9@._+-]'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PasswordTextField(
                label: 'Пароль',
                hint: 'Минимум 8 символов',
                controller: viewModel.passwordController,
                isVisible: state.isPasswordVisible,
                onToggleVisibility: viewModel.changePasswordVisibility,
                enabled: !state.isLoading,
                errorText: state.passwordError,
                onChanged: viewModel.resetPassword,
                onSubmitted: viewModel.onPasswordSubmit,
                focusNode: viewModel.passwordFocusNode,
              ),
              const SizedBox(height: 24),
              _PasswordTextField(
                label: 'Повторите пароль',
                hint: 'Введите пароль еще раз',
                controller: viewModel.confirmPasswordController,
                isVisible: state.isConfirmPasswordVisible,
                onToggleVisibility: viewModel.changeConfirmPasswordVisible,
                enabled: !state.isLoading,
                errorText: state.confirmPasswordError,
                onChanged: viewModel.resetConfirmPassword,
                onSubmitted: viewModel.onConfirmPasswordSubmit,
                focusNode: viewModel.confirmPasswordFocusNode,
              ),
              const SizedBox(height: 32),
              _SignUpButton(
                isLoading: state.isLoading,
                onPressed: () => viewModel.create(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Текстовое поле
class _SignUpTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const _SignUpTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onSubmitted,
    this.keyboardType,
    this.prefixIcon,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
          inputFormatters: inputFormatters,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  )
                : null,
            errorText: errorText,
            errorStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Поле пароля с возможностью показать/скрыть
class _PasswordTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSubmitted;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const _PasswordTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onSubmitted,
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
          focusNode: focusNode,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 22,
              ),
              onPressed: onToggleVisibility,
            ),
            errorText: errorText,
            errorStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Кнопка регистрации
class _SignUpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignUpButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : const Text(
              'Создать аккаунт',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}

// Ссылка на вход
class _SignInLink extends StatelessWidget {
  const _SignInLink();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Уже есть аккаунт? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        TextButton(
          onPressed: () {
            // Навигация на страницу входа
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Войти',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
