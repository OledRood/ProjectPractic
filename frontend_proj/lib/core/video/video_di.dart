import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/video/services/video_api_service.dart';

/// Провайдер для VideoApiService
final videoApiServiceProvider = Provider<VideoApiService>((ref) {
  return VideoApiService();
});

/// Провайдер для проверки работоспособности сервера
final serverHealthProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(videoApiServiceProvider);
  return await service.healthCheck();
});
