import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
          ..preload = 'metadata'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.borderRadius = '16px';

        // Добавляем обработчики событий для отладки
        videoElement.onLoadedMetadata.listen((event) {
          debugPrint('✅ Video metadata loaded for: $videoPath');
        });

        videoElement.onError.listen((event) {
          debugPrint('❌ Video error for: $videoPath');
          debugPrint(
            'Error: ${videoElement.error?.code} - ${videoElement.error?.message}',
          );
        });

        videoElement.onCanPlay.listen((event) {
          debugPrint('▶️ Video can play: $videoPath');
        });

        return videoElement;
      });
      _isViewRegistered = true;
      debugPrint('Video element registered successfully: $_videoViewId');
    } catch (e) {
      debugPrint('Error registering video view: $e');
    }
  }

  String _getExerciseTypeName(String? exerciseType) {
    if (exerciseType == null) return 'Не определено';
    switch (exerciseType) {
      case 'push_up':
        return 'Отжимания';
      case 'squat':
        return 'Приседания';
      case 'long_jump':
        return 'Прыжок в длину';
      default:
        return exerciseType;
    }
  }

  String _getCorrectnessName(String? correctness) {
    if (correctness == null) return 'Не определено';
    switch (correctness) {
      case 'correct':
        return 'Правильно ✓';
      case 'incorrect':
        return 'Неправильно ✗';
      case 'partial':
        return 'Частично правильно';
      default:
        return correctness;
    }
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Карточка с результатами от сервера
              if (state.exerciseType != null) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_rounded,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Результаты анализа',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildResultRow(
                        context,
                        'Тип упражнения',
                        _getExerciseTypeName(state.exerciseType),
                        Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        context,
                        'Правильность',
                        _getCorrectnessName(state.correctness),
                        Icons.check_circle_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        context,
                        'Уверенность модели',
                        state.confidence != null
                            ? '${(state.confidence! * 100).toStringAsFixed(1)}%'
                            : 'Не определено',
                        Icons.speed_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
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
