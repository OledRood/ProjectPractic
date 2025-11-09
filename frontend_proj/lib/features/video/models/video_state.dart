import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_state.freezed.dart';

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
    String? exerciseType,
    String? correctness,
    double? confidence,
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
