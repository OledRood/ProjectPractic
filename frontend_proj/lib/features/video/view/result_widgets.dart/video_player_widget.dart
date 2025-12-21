import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({
    super.key,
    required this.videoFromServerPath,
    required this.isViewRegistered,
    required this.videoViewId,
  });

  final String? videoFromServerPath;
  final bool isViewRegistered;
  final String videoViewId;

  @override
  Widget build(BuildContext context) {
    if (videoFromServerPath != null && isViewRegistered) {
      return Column(
        children: [
          VideoWidget(videoViewId: videoViewId),
          const SizedBox(height: 24),
        ],
      );
    } else if (videoFromServerPath == null) {
      return NotFoundVideoCard();
    } else {
      return Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Загрузка видеоплеера...'),
        ],
      );
    }
  }
}

class VideoWidget extends StatelessWidget {
  const VideoWidget({super.key, required String videoViewId})
    : _videoViewId = videoViewId;

  final String _videoViewId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 225),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
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
              : const Center(child: Text('Видеоплеер доступен только в Web')),
        ),
      ),
    );
  }
}

class NotFoundVideoCard extends StatelessWidget {
  const NotFoundVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 32),
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
    );
  }
}
