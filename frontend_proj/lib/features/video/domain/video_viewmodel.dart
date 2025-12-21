import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/message/message_di.dart';
import 'package:frontend_proj/core/message/scaffold_messenger_manager.dart';
import 'package:frontend_proj/core/navigation/app_navigation.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend_proj/core/video/services/video_api_service.dart';
import 'package:frontend_proj/core/video/models/video_task.dart';
import 'package:frontend_proj/core/video/video_di.dart';

class VideoViewmodel extends Notifier<VideoState> {
  VideoViewmodel();
  AppNavigation get _navigation => ref.read(appNavigationProvider);
  ScaffoldMessengerManager get _scaffoldMessenger =>
      ref.read(MessageDi.scaffoldMessengerManager);
  VideoApiService get _videoApiService => ref.read(videoApiServiceProvider);

  @override
  VideoState build() {
    return VideoState();
  }

  void _navigateByStatus(VideoStatus status) {
    switch (status) {
      case VideoStatus.getVideo:
        _navigation.goToGetVideo();
        break;
      case VideoStatus.loading:
        _navigation.goToLoading();
        break;
      case VideoStatus.result:
        _navigation.goToResult();
        break;
    }
  }

  void error(String error) {
    _scaffoldMessenger.showErrorSnackBar(error);
  }

  void onUploadVideoTap(String? videoPath, {Uint8List? videoBytes}) {
    state = state.copyWith(
      videoFromUserPath: videoPath,
      videoBytes: videoBytes,
      errorMessage: null,
    );
  }

  void setVideoDuration(Duration? duration) {
    state = state.copyWith(videoDuration: duration);
  }

  void showProcessingInfo() {
    state = state.copyWith(showProcessingInfoDialog: true);
  }

  void hideProcessingInfo() {
    state = state.copyWith(showProcessingInfoDialog: false);
  }

  void onSendButtonTap() {
    if (state.isLoading) return;
    state = state.copyWith(errorMessage: null, isLoading: true);
    if (state.status != VideoStatus.getVideo) {
      state = state.copyWith(isLoading: false);
      return;
    }
    if (state.videoFromUserPath == null || state.videoFromUserPath!.isEmpty) {
      state = state.copyWith(
        errorMessage: "Пожалуйста, загрузите видео",
        isLoading: false,
      );
      _scaffoldMessenger.showErrorSnackBar(state.errorMessage!);
      return;
    }
    state = state.copyWith(
      status: VideoStatus.loading,
      errorMessage: null,
      isLoading: false,
    );
    _navigateByStatus(VideoStatus.loading);
    _sendVideoToServer();
  }

  Future<void> _sendVideoToServer() async {
    try {
      if (state.videoFromUserPath == null) {
        throw Exception('Video path is null');
      }

      debugPrint('🚀 Отправка видео на сервер: ${state.videoFromUserPath}');

      // Шаг 1: Загрузка видео на сервер
      late UploadResponse uploadResponse;

      if (kIsWeb) {
        // Для Web используем байты
        if (state.videoBytes == null) {
          throw Exception('Video bytes are null for web');
        }
        uploadResponse = await _videoApiService.uploadVideoBytes(
          state.videoBytes!,
          state.videoFromUserPath!, // Имя файла
          onProgress: (progress) {
            debugPrint('📤 Загрузка: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );
      } else {
        // Для мобильных платформ используем File
        final videoFile = File(state.videoFromUserPath!);
        uploadResponse = await _videoApiService.uploadVideo(
          videoFile,
          onProgress: (progress) {
            debugPrint('📤 Загрузка: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );
      }

      final taskId = uploadResponse.taskId;
      debugPrint('✅ Видео загружено, Task ID: $taskId');

      // Обновляем состояние с taskId сразу после загрузки
      state = state.copyWith(taskId: taskId);

      debugPrint('⏳ Начинаю опрос статуса...');

      // Шаг 2: Опрос статуса обработки
      await for (final task in _videoApiService.pollStatus(taskId)) {
        debugPrint('📊 Статус: ${task.status.value}');

        if (task.status == TaskStatus.completed) {
          final result = task.result!;
          debugPrint('🎉 Обработка завершена!');
          debugPrint('📝 Результаты от модели:');
          debugPrint('   - Статус: ${result.status}');
          debugPrint('   - Упражнение: ${result.exercise}');
          debugPrint(
            '   - Уверенность: ${result.confidence?.toStringAsFixed(1)}%',
          );
          debugPrint('   - Проблемы техники: ${result.techniqueIssues.length}');
          debugPrint('   - Метрики: ${result.metrics}');

          // Проверяем на ошибку от модели
          if (result.hasError) {
            state = state.copyWith(
              analysisError: result.error ?? 'Ошибка анализа видео',
              status: VideoStatus.result,
              isLoading: false,
              taskId: taskId,
            );
            await Future.delayed(Duration.zero);
            _navigateByStatus(VideoStatus.result);
            return;
          }

          // Успешная обработка - сохраняем данные от модели
          final resultVideoUrl = 'http://localhost:8000/api/result/$taskId';

          state = state.copyWith(
            videoFromServerPath: resultVideoUrl,
            status: VideoStatus.result,
            isLoading: false,
            taskId: taskId,
            // Данные от модели
            exercise: result.exercise,
            confidence: result.confidence,
            techniqueIssues: result.techniqueIssues,
            metrics: result.metrics,
            analysisError: null,
          );

          await Future.delayed(Duration.zero);
          _navigateByStatus(VideoStatus.result);
          return;
        }

        if (task.status == TaskStatus.failed) {
          throw VideoApiException(
            task.error ?? 'Ошибка обработки видео на сервере',
          );
        }

        // Для статусов queued и processing продолжаем ожидание
        if (task.status == TaskStatus.queued) {
          debugPrint('⏸️ Видео в очереди на обработку...');
        } else if (task.status == TaskStatus.processing) {
          debugPrint('⚙️ Видео обрабатывается...');
        }
      }
    } on VideoApiException catch (e) {
      debugPrint('❌ Ошибка API: ${e.message}');
      state = state.copyWith(
        errorMessage: e.message,
        status: VideoStatus.getVideo,
        isLoading: false,
      );
      _scaffoldMessenger.showErrorSnackBar(e.message);
      _navigateByStatus(VideoStatus.getVideo);
    } catch (e) {
      debugPrint('❌ Неожиданная ошибка: $e');
      state = state.copyWith(
        errorMessage: "Ошибка при отправке видео на сервер: $e",
        status: VideoStatus.getVideo,
        isLoading: false,
      );
      _scaffoldMessenger.showErrorSnackBar(state.errorMessage!);
      _navigateByStatus(VideoStatus.getVideo);
    }
  }

  void onRestartVideoSendButtonTap() {
    _navigateByStatus(VideoStatus.getVideo);

    state = state.copyWith(
      status: VideoStatus.getVideo,
      errorMessage: null,
      videoFromUserPath: null,
      videoFromServerPath: null,
      videoDuration: null,
      isLoading: false,
      videoBytes: null,
      // Сбрасываем данные от модели
      taskId: null,
      exercise: null,
      confidence: null,
      techniqueIssues: null,
      metrics: null,
      analysisError: null,
    );
  }
}
