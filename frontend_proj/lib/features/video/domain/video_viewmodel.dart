import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/message/message_di.dart';
import 'package:frontend_proj/core/message/scaffold_messenger_manager.dart';
import 'package:frontend_proj/core/navigation/app_navigation.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';
import 'package:flutter/foundation.dart';

class VideoViewmodel extends Notifier<VideoState> {
  VideoViewmodel();
  AppNavigation get _navigation => ref.read(appNavigationProvider);
  ScaffoldMessengerManager get _scaffoldMessenger =>
      ref.read(MessageDi.scaffoldMessengerManager);
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

  void onUploadVideoTap(String? videoPath) {
    state = state.copyWith(videoFromUserPath: videoPath, errorMessage: null);
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
      debugPrint('Sending video to server...');
      await Future.delayed(const Duration(seconds: 1));

      // Simulate a successful response from the server with a video path
      // Используем тестовое видео из интернета
      const serverVideoPath =
          "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";

      debugPrint('Video processed successfully, navigating to result page');
      state = state.copyWith(
        videoFromServerPath: serverVideoPath,
        status: VideoStatus.result,
        isLoading: false,
      );
      debugPrint(
        'State updated: videoFromServerPath=${state.videoFromServerPath}',
      );

      // Отложенная навигация после обновления состояния
      await Future.delayed(Duration.zero);
      _navigateByStatus(VideoStatus.result);
    } catch (e) {
      debugPrint('Error sending video: $e');
      state = state.copyWith(
        errorMessage: "Ошибка при отправке видео на сервер",
        status: VideoStatus.getVideo,
        isLoading: false,
      );

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
    );
  }
}
