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

  String _getExerciseDisplayName(String? exercise) {
    if (exercise == null) return 'Не определено';
    switch (exercise) {
      case 'pushup':
        return 'Отжимания';
      case 'pullup':
        return 'Подтягивания';
      case 'unknown':
        return 'Не определено';
      default:
        return exercise;
    }
  }

  /// Форматирование названия метрики для отображения
  String _formatMetricName(String key) {
    switch (key) {
      case 'elbow_angle':
        return 'Угол локтя';
      case 'torso_angle':
        return 'Угол туловища';
      case 'knee_angle':
        return 'Угол колена';
      case 'shoulders_high':
        return 'Плечи выше локтей';
      default:
        return key;
    }
  }

  /// Форматирование значения метрики
  String _formatMetricValue(dynamic value) {
    if (value is bool) {
      return value ? 'Да ✓' : 'Нет ✗';
    } else if (value is double) {
      return '${value.toStringAsFixed(1)}°';
    } else if (value is int) {
      return '$value°';
    }
    return value.toString();
  }

  /// Склонение слов в зависимости от числа
  String _getPluralForm(int number, String one, String few, String many) {
    final n = number % 100;
    if (n >= 11 && n <= 19) return many;
    final lastDigit = n % 10;
    if (lastDigit == 1) return one;
    if (lastDigit >= 2 && lastDigit <= 4) return few;
    return many;
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
              // Карточка с ошибкой анализа (если есть)
              if (state.analysisError != null) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ошибка анализа',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.analysisError!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Карточка с результатами от модели
              if (state.exercise != null) ...[
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
                        _getExerciseDisplayName(state.exercise),
                        Icons.fitness_center_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        context,
                        'Уверенность модели',
                        state.confidence != null
                            ? '${state.confidence!.toStringAsFixed(1)}%'
                            : 'Не определено',
                        Icons.speed_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Карточка с оценкой техники
              if (state.exercise != null) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (state.techniqueIssues?.isEmpty ?? true)
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : colorScheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (state.techniqueIssues?.isEmpty ?? true)
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (state.techniqueIssues?.isEmpty ?? true)
                                ? Icons.check_circle_rounded
                                : Icons.warning_rounded,
                            size: 32,
                            color: (state.techniqueIssues?.isEmpty ?? true)
                                ? colorScheme.primary
                                : colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Оценка техники',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.techniqueIssues?.isEmpty ?? true) ...[
                        // Хорошая техника
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up_rounded,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Техника идеальна! ✓',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Предупреждений не обнаружено',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme
                                                .onPrimaryContainer
                                                .withOpacity(0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Есть проблемы с техникой
                        Text(
                          'Обнаружено ${state.techniqueIssues!.length} ${_getPluralForm(state.techniqueIssues!.length, 'проблема', 'проблемы', 'проблем')}:',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...state.techniqueIssues!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final issue = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: colorScheme.onError,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      issue,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Карточка с метриками
              if (state.metrics != null && state.metrics!.isNotEmpty) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 32,
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Измеренные углы',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: state.metrics!.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatMetricName(entry.key),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onTertiaryContainer
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMetricValue(entry.value),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
