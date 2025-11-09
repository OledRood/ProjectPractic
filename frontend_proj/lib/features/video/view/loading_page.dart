import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';
import 'package:go_router/go_router.dart';

class LoadingPage extends ConsumerWidget {
  const LoadingPage({super.key});

  String _getStatusMessage(VideoState state) {
    if (state.taskId == null) {
      return 'Загрузка видео на сервер...';
    }

    // Здесь состояние обновляется из viewmodel через pollStatus
    return 'Обработка видео...';
  }

  String _getEstimatedTime(VideoState state) {
    if (state.estimatedProcessingTime != null) {
      final minutes = state.estimatedProcessingTime!.inMinutes;
      final seconds = state.estimatedProcessingTime!.inSeconds % 60;
      if (minutes > 0) {
        return 'Примерное время: $minutes мин $seconds сек';
      }
      return 'Примерное время: $seconds сек';
    }
    return 'Идет обработка...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(VideoDi.videoViewmodelProvider);
    final theme = Theme.of(context);

    debugPrint('LoadingPage: status=${state.status}, taskId=${state.taskId}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обработка видео'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.signInPage.path);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Анимированная иконка
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.video_settings,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(value),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Заголовок
              Text(
                _getStatusMessage(state),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Информация о времени
              if (state.taskId != null) ...[
                Text(
                  _getEstimatedTime(state),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Task ID: ${state.taskId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),

              // Прогресс бар
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    const LinearProgressIndicator(
                      minHeight: 8,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Пожалуйста, не закрывайте эту страницу',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
