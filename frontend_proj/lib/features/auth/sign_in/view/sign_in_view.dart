import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/auth/sign_in/auth_di.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: _SignInPageBackground(
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
                    const _SignInHeader(),
                    const SizedBox(height: 40),
                    _SignInFormCard(isMobile: isMobile),
                    const SizedBox(height: 24),
                    const _SignUpLink(),
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
class _SignInPageBackground extends StatelessWidget {
  final Widget child;

  const _SignInPageBackground({required this.child});

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
class _SignInHeader extends StatelessWidget {
  const _SignInHeader();

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
          child: const Icon(Icons.login_rounded, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'Вход в аккаунт',
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
class _SignInFormCard extends ConsumerWidget {
  final bool isMobile;

  const _SignInFormCard({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(SignInDi.signInViewmodelProvider.notifier);
    final state = ref.watch(SignInDi.signInViewmodelProvider);
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
              // Email поле
              TextFormField(
                controller: viewModel.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => viewModel.onEmailSubmit(),
                onChanged: (_) => viewModel.resetEmail(),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@mail.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: state.emailError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              // Password поле
              TextFormField(
                controller: viewModel.passwordController,
                focusNode: viewModel.passwordFocusNode,
                obscureText: !state.isPasswordVisible,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => viewModel.onPasswordSubmit(),
                onChanged: viewModel.resetPassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: state.passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      state.isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: viewModel.changePasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              // Кнопка входа
              FilledButton(
                onPressed: state.isLoading ? null : viewModel.signIn,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ссылка на регистрацию
class _SignUpLink extends ConsumerWidget {
  const _SignUpLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(SignInDi.signInViewmodelProvider.notifier);
    final state = ref.watch(SignInDi.signInViewmodelProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Нет аккаунта? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        TextButton(
          onPressed: state.isLoading ? null : viewModel.goToSignUp,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Зарегистрироваться',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
