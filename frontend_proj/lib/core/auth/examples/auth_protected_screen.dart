import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth.dart';

/// Пример защищенного виджета, который показывает разный контент
/// в зависимости от состояния аутентификации
class AuthProtectedScreen extends ConsumerWidget {
  const AuthProtectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      initial: () => _buildLoading(),
      loading: () => _buildLoading(),
      authenticated: (user) => _buildAuthenticated(context, ref, user),
      unauthenticated: () => _buildUnauthenticated(context),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildAuthenticated(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authNotifier = ref.read(authNotifierProvider.notifier);
              await authNotifier.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user.avatarUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(user.avatarUrl!),
              )
            else
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            const SizedBox(height: 16),
            Text(
              user.name ?? 'Без имени',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
            if (!user.isEmailVerified) ...[
              const SizedBox(height: 16),
              Chip(
                label: const Text('Email не подтвержден'),
                backgroundColor: Colors.orange.shade100,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Не авторизован')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80),
            const SizedBox(height: 16),
            const Text('Пожалуйста, войдите в систему'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Навигация на страницу входа
                // Navigator.pushNamed(context, '/login');
              },
              child: const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пример кастомного хука для проверки авторизации
extension AuthStateExtension on WidgetRef {
  /// Проверить авторизован ли пользователь
  bool get isAuthenticated {
    final notifier = read(authNotifierProvider.notifier);
    return notifier.isAuthenticated;
  }

  /// Получить текущего пользователя
  UserModel? get currentUser {
    final notifier = read(authNotifierProvider.notifier);
    return notifier.currentUser;
  }

  /// Выполнить logout
  Future<void> logout() async {
    final notifier = read(authNotifierProvider.notifier);
    await notifier.signOut();
  }
}
