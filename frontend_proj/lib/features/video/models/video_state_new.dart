import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_state_new.freezed.dart';

enum VideoStatus { getVideo, loading, result }

@freezed
sealed class VideoState with _$VideoState {
  const VideoState._();
  factory VideoState({
    String? videoFromUserPath,
    String? videoFromServerPath,
    String? errorMessage,
    @Default(false) bool isLoading,
    @Default(VideoStatus.getVideo) VideoStatus status,
    Duration? videoDuration,
    @Default(false) bool showProcessingInfoDialog,
    // Данные с сервера
    String? taskId,
    // === ДАННЫЕ ОТ МОДЕЛИ (реальные) ===
    /// Тип упражнения: "pushup", "pullup", "unknown"
    String? exercise,
    /// Уверенность модели (0-100%)
    double? confidence,
    /// Список проблем с техникой от модели (может быть пустым = хорошая техника)
    List<String>? techniqueIssues,
    /// Метрики углов от модели (elbow_angle, torso_angle, knee_angle, shoulders_high)
    Map<String, dynamic>? metrics,
    /// Ошибка анализа от модели (если status == "error")
    String? analysisError,
    // Для Web: байты файла
    Uint8List? videoBytes,
  }) = _VideoState;

  bool get hasVideo =>
      videoFromUserPath != null && videoFromUserPath!.isNotEmpty;

  /// Расчет примерного времени обработки видео
  /// Бэк обрабатывает 25 кадров/сек, стандартное видео - 30 кадров/сек
  Duration? get estimatedProcessingTime {
    if (videoDuration == null) return null;

    const framesPerSecond = 30; // Стандартное количество кадров в секунде видео
    const processingSpeed = 25; // Бэк обрабатывает 25 кадров за 1 секунду

    final totalFrames = videoDuration!.inSeconds * framesPerSecond;
    final processingTimeInSeconds = totalFrames / processingSpeed;

    return Duration(seconds: processingTimeInSeconds.ceil());
  }
}
