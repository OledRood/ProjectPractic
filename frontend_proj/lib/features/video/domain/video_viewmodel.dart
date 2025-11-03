import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/navigation/app_navigation.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';

class VideoViewmodel extends Notifier<VideoState> {
  VideoViewmodel() {}
  AppNavigation get _navigation => ref.read(appNavigationProvider);

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

  void onUploadVideoTap(String? videoPath) {
    state = state.copyWith(videoFromUserPath: videoPath);
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
      await Future.delayed(const Duration(seconds: 2));

      // Simulate a successful response from the server with a video path
      const serverVideoPath = "server/path/to/processed_video.mp4";

      state = state.copyWith(
        videoFromServerPath: serverVideoPath,
        status: VideoStatus.result,
        isLoading: false,
      );
      _navigateByStatus(VideoStatus.result);
    } catch (e) {
      state = state.copyWith(
        errorMessage: "Ошибка при отправке видео на сервер",
        status: VideoStatus.getVideo,
        isLoading: false,
      );
      _navigateByStatus(VideoStatus.getVideo);
    }
  }

  void onRestartVideoSendButtonTap() {
    state = state.copyWith(
      status: VideoStatus.getVideo,
      errorMessage: null,
      videoFromUserPath: null,
      videoFromServerPath: null,
      isLoading: false,
    );
    _navigateByStatus(VideoStatus.getVideo);
  }
}
