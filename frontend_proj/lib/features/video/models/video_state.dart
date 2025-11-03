import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_state.freezed.dart';

enum VideoStatus { getVideo, loading, result }

@freezed
sealed class VideoState with _$VideoState {
  factory VideoState({
    String? videoFromUserPath,
    String? videoFromServerPath,
    String? errorMessage,
    @Default(false) bool isLoading,
    @Default(VideoStatus.getVideo) VideoStatus status,
  }) = _VideoState;
}
