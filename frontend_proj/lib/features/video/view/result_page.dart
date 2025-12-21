import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/features/video/domain/video_viewmodel.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Условные импорты для Web
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

import 'package:frontend_proj/features/video/view/result_widgets.dart/analysis_error_card.dart';
import 'package:frontend_proj/features/video/view/result_widgets.dart/analysis_result_card.dart';
import 'package:frontend_proj/features/video/view/result_widgets.dart/metric_card.dart';
import 'package:frontend_proj/features/video/view/result_widgets.dart/technique_assessment_card.dart';
import 'package:frontend_proj/features/video/view/result_widgets.dart/video_player_widget.dart';

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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Карточка с ошибкой анализа (если есть)
              if (state.analysisError != null) ...[
                AnalysisErrorCard(analysisError: state.analysisError!),
                const SizedBox(height: 32),
              ],

              // Карточка с результатами от модели (адаптивная верстка)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1025;
                  final isMedium = constraints.maxWidth > 725;
                  
                  // Ширина для MetricsCard зависит от размера экрана
                  final metricsWidth = isWide 
                      ? 450.0 
                      : isMedium 
                          ? 380.0 
                          : constraints.maxWidth;
                  
                  // Ширина для левой колонки
                  final leftColumnWidth = isWide 
                      ? constraints.maxWidth - metricsWidth - 24 
                      : isMedium 
                          ? constraints.maxWidth - metricsWidth - 24 
                          : constraints.maxWidth;

                  final leftColumn = SizedBox(
                    width: isMedium ? leftColumnWidth : null,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: AnalysisResultCard(
                            confidence: state.confidence,
                            exercise: state.exercise,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: isMedium ? 0 : 24),
                          child: TechniqueAssessmentCard(
                            techniqueIssues: state.techniqueIssues,
                            exercise: state.exercise,
                          ),
                        ),
                      ],
                    ),
                  );

                  final metricsCard = SizedBox(
                    width: metricsWidth,
                    child: MetricsCard(
                      metrics: state.metrics,
                      videoWidget: VideoPlayerWidget(
                        videoFromServerPath: state.videoFromServerPath,
                        isViewRegistered: _isViewRegistered,
                        videoViewId: _videoViewId,
                      ),
                    ),
                  );

                  // Горизонтальная верстка для широких экранов
                  if (isMedium) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftColumn,
                          const SizedBox(width: 24),
                          metricsCard,
                        ],
                      ),
                    );
                  }

                  // Вертикальная верстка для узких экранов
                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 24),
                      metricsCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Кнопки действий
              ButtonWidgets(
                onRestartVideoSendButtonTap: () {
                  vm.onRestartVideoSendButtonTap();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ButtonWidgets extends StatelessWidget {
  const ButtonWidgets({super.key, required this.onRestartVideoSendButtonTap});

  final VoidCallback onRestartVideoSendButtonTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onRestartVideoSendButtonTap,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Загрузить новое видео'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}
