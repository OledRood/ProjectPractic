import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend_proj/features/video/domain/video_viewmodel.dart';
import 'package:frontend_proj/features/video/models/video_state.dart';

class VideoDi {
  VideoDi._();

  static final videoViewmodelProvider =
      NotifierProvider<VideoViewmodel, VideoState>(VideoViewmodel.new);
}
