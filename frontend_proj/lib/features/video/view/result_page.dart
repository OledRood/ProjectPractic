import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

// Условные импорты для Web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  static int _viewIdCounter = 0;
  late final String _videoViewId;
  bool _isViewRegistered = false;

  @override
  void initState() {
    super.initState();
    _videoViewId = 'result-video-player-${_viewIdCounter++}';
    debugPrint('ResultPage: initState called, viewId=$_videoViewId');
  }

  void _registerVideoElement(String videoPath) {
    if (!kIsWeb || _isViewRegistered || videoPath.isEmpty) {
      debugPrint(
        'Skipping video registration: kIsWeb=$kIsWeb, isRegistered=$_isViewRegistered, path=$videoPath',
      );
      return;
    }

    try {
      debugPrint(
        'Registering video element: $_videoViewId with path: $videoPath',
      );
      // Регистрируем HTML элемент для Flutter Web
      ui_web.platformViewRegistry.registerViewFactory(_videoViewId, (
        int viewId,
      ) {
        final videoElement = html.VideoElement()
          ..src = videoPath
          ..controls = true
          ..autoplay = false
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.borderRadius = '16px';

        return videoElement;
      });
      _isViewRegistered = true;
      debugPrint('Video element registered successfully: $_videoViewId');
    } catch (e) {
      debugPrint('Error registering video view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(VideoDi.videoViewmodelProvider.notifier);
    final state = ref.watch(VideoDi.videoViewmodelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    debugPrint(
      'ResultPage build: videoFromServerPath=${state.videoFromServerPath}, isRegistered=$_isViewRegistered',
    );

    // Регистрируем видео элемент ОДИН РАЗ когда путь становится доступным
    if (!_isViewRegistered &&
        state.videoFromServerPath != null &&
        state.videoFromServerPath!.isNotEmpty) {
      // Регистрируем сразу, не откладывая
      _registerVideoElement(state.videoFromServerPath!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результат обработки'),
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Видеоплеер
              if (state.videoFromServerPath != null && _isViewRegistered) ...[
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                    maxHeight: 450,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: kIsWeb
                          ? HtmlElementView(viewType: _videoViewId)
                          : const Center(
                              child: Text('Видеоплеер доступен только в Web'),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (state.videoFromServerPath == null) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Видео не найдено',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Загрузка видеоплеера...'),
              ],

              const SizedBox(height: 40),

              // Кнопки действий
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => vm.onRestartVideoSendButtonTap(),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Загрузить новое видео'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Видеоплеер
              if (state.videoFromServerPath != null) ...[
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                    maxHeight: 450,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: kIsWeb
                          ? HtmlElementView(viewType: _videoViewId)
                          : const Center(
                              child: Text('Видеоплеер доступен только в Web'),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Информация о видео
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Обработанное видео',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.videoFromServerPath!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer
                                    .withOpacity(0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Видео не найдено',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Кнопки действий
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  if (state.videoFromServerPath != null)
                    FilledButton.tonalIcon(
                      onPressed: () {
                        // Скачать видео
                        if (kIsWeb && state.videoFromServerPath != null) {
                          final anchor = html.document.createElement('a');
                          anchor.setAttribute(
                            'href',
                            state.videoFromServerPath!,
                          );
                          anchor.setAttribute(
                            'download',
                            'processed_video.mp4',
                          );
                          anchor.click();
                        }
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Скачать видео'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: () => vm.onRestartVideoSendButtonTap(),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Загрузить новое видео'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Здесь можно добавить функционал истории
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Функция в разработке'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Предыдущие результаты'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
