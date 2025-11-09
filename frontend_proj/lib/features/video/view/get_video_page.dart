import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/auth/auth_di.dart';
import 'package:frontend_proj/core/navigation/app_routes.dart';
import 'package:frontend_proj/features/video/video_di.dart';
import 'package:frontend_proj/features/video/domain/video_viewmodel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:go_router/go_router.dart';

class GetVideoPage extends ConsumerWidget {
  const GetVideoPage({super.key});

  void _showProcessingInfoDialog(BuildContext context, VideoViewmodel vm) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(VideoDi.videoViewmodelProvider);
            return ProcessingInfoDialog(
              videoDuration: state.videoDuration,
              estimatedProcessingTime: state.estimatedProcessingTime,
              onClose: () {
                vm.hideProcessingInfo();
                Navigator.of(dialogContext).pop();
              },
            );
          },
        );
      },
    ).then((_) => vm.hideProcessingInfo());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(VideoDi.videoViewmodelProvider.notifier);
    final state = ref.watch(VideoDi.videoViewmodelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Слушаем изменения состояния для показа диалога
    ref.listen(VideoDi.videoViewmodelProvider, (previous, next) {
      if (next.showProcessingInfoDialog &&
          !previous!.showProcessingInfoDialog) {
        _showProcessingInfoDialog(context, vm);
      }
    });

    String _formatDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      if (hours > 0) {
        return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes}:${seconds.toString().padLeft(2, '0')}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Video Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.signInPage.path);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text("Выберете видео для обработки"),
                const SizedBox(height: 20),
                _VideoPickerWidget(),
                const SizedBox(height: 20),

                Row(
                  children: [
                    if (state.videoDuration != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => vm.showProcessingInfo(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: colorScheme.onPrimaryContainer.withOpacity(
                                0.8,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(state.videoDuration!),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer
                                    .withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => vm.onSendButtonTap(),
                      child: Text("Send Video"),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPickerWidget extends ConsumerStatefulWidget {
  const _VideoPickerWidget();

  @override
  ConsumerState<_VideoPickerWidget> createState() => _VideoPickerWidgetState();
}

class _VideoPickerWidgetState extends ConsumerState<_VideoPickerWidget> {
  bool _isDragging = false;

  Future<void> _pickVideo() async {
    try {
      // Выбираем видео файл
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb, // Для web нужно загружать данные
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Для web используем имя файла или bytes
        String? videoPath;
        if (kIsWeb) {
          // В web версии можем использовать имя файла или создать blob URL
          videoPath = file.name;

          // Получаем длительность видео для web
          if (file.bytes != null) {
            _getVideoDuration(file.bytes!);
          }
        } else {
          videoPath = file.path;
        }

        // Вызываем метод viewmodel для сохранения пути к видео
        ref
            .read(VideoDi.videoViewmodelProvider.notifier)
            .onUploadVideoTap(videoPath);
      }
    } catch (e) {
      ref
          .read(VideoDi.videoViewmodelProvider.notifier)
          .error("Ошибка при выборе видео: $e");
    }
  }

  Future<void> _getVideoDuration(List<int> bytes) async {
    if (!kIsWeb) return;

    try {
      // Создаем Blob из bytes
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Создаем video element
      final video = html.VideoElement()
        ..src = url
        ..preload = 'metadata';

      // Ждем загрузки метаданных
      final completer = Completer<void>();

      video.onLoadedMetadata.listen((_) {
        final duration = video.duration;
        if (!duration.isNaN && !duration.isInfinite) {
          final videoDuration = Duration(
            milliseconds: (duration * 1000).toInt(),
          );
          ref
              .read(VideoDi.videoViewmodelProvider.notifier)
              .setVideoDuration(videoDuration);
        }

        // Освобождаем URL
        html.Url.revokeObjectUrl(url);
        completer.complete();
      });

      video.onError.listen((_) {
        ref
            .read(VideoDi.videoViewmodelProvider.notifier)
            .error("Ошибка при загрузке видео");

        html.Url.revokeObjectUrl(url);
        completer.complete();
      });

      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          ref
              .read(VideoDi.videoViewmodelProvider.notifier)
              .error("Ошибка при получении длительности видео");

          html.Url.revokeObjectUrl(url);
        },
      );
    } catch (e) {
      ref
          .read(VideoDi.videoViewmodelProvider.notifier)
          .error("Ошибка при получении длительности видео");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(VideoDi.videoViewmodelProvider);
    final hasVideo = state.hasVideo;
    final errorMessage = state.errorMessage;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 300,
      width: 450,
      decoration: BoxDecoration(
        color: _isDragging
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : hasVideo
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDragging
              ? colorScheme.primary
              : hasVideo
              ? colorScheme.primary
              : errorMessage == null
              ? colorScheme.outline
              : colorScheme.error,
          width: _isDragging ? 3 : 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: kIsWeb
            ? Stack(
                children: [
                  // Dropzone на весь контейнер
                  Positioned.fill(
                    child: DropzoneView(
                      onDrop: _handleDrop,
                      onHover: () => setState(() => _isDragging = true),
                      onLeave: () => setState(() => _isDragging = false),
                    ),
                  ),
                  // Контент поверх dropzone
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: false,
                      child: _buildContent(
                        context,
                        theme,
                        colorScheme,
                        hasVideo,
                      ),
                    ),
                  ),
                ],
              )
            : _buildContent(context, theme, colorScheme, hasVideo),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool hasVideo,
  ) {
    final state = ref.watch(VideoDi.videoViewmodelProvider);
    final errorMessage = state.errorMessage;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickVideo(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _isDragging
                    ? Icons.cloud_upload_rounded
                    : hasVideo
                    ? Icons.video_file_rounded
                    : Icons.video_library_rounded,
                size: 64,
                color: _isDragging
                    ? colorScheme.primary
                    : hasVideo
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _isDragging
                    ? 'Отпустите файл для загрузки'
                    : hasVideo
                    ? 'Видео выбрано'
                    : 'Нажмите для выбора видео',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _isDragging
                      ? colorScheme.primary
                      : hasVideo
                      ? colorScheme.onPrimaryContainer
                      : errorMessage == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.error,
                  fontWeight: hasVideo || _isDragging
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
              if (hasVideo) ...[
                const SizedBox(height: 8),
                Text(
                  state.videoFromUserPath ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _pickVideo(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Выбрать другое'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDrop(dynamic event) async {
    if (!kIsWeb) return;

    setState(() => _isDragging = false);

    try {
      // Проверяем, что event это html.File
      if (event is! html.File) {
        ref
            .read(VideoDi.videoViewmodelProvider.notifier)
            .error("Неверный формат файла");
        return;
      }

      final file = event;

      // Проверяем MIME-тип
      if (!file.type.startsWith('video/')) {
        ref
            .read(VideoDi.videoViewmodelProvider.notifier)
            .error("Пожалуйста, выберите видео файл");
        return;
      }

      // Читаем файл как bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      await reader.onLoadEnd.first;

      if (reader.result != null) {
        final bytes = reader.result as List<int>;

        // Сохраняем видео
        ref
            .read(VideoDi.videoViewmodelProvider.notifier)
            .onUploadVideoTap(file.name);

        // Получаем длительность
        _getVideoDuration(bytes);
      }
    } catch (e) {
      ref
          .read(VideoDi.videoViewmodelProvider.notifier)
          .error("Ошибка при загрузке видео: $e");
    }
  }
}

class ProcessingInfoDialog extends StatelessWidget {
  final VoidCallback onClose;
  final Duration? videoDuration;
  final Duration? estimatedProcessingTime;

  const ProcessingInfoDialog({
    super.key,
    required this.onClose,
    this.videoDuration,
    this.estimatedProcessingTime,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}ч ${minutes} мин ${seconds} сек';
    } else if (minutes > 0) {
      return '${minutes} мин ${seconds} сек';
    } else {
      return '${seconds} сек';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'О скорости обработки',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Основной текст с информацией
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Первый пункт
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Стандартное видео содержит 30 кадров в секунду',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Второй пункт
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Сервер обрабатывает 25 кадров за 1 секунду',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Третий пункт - расчет
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calculate_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Время обработки рассчитывается как:\n(длительность видео × 30 кадров) ÷ 25 кадров/сек',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Если есть информация о видео, показываем расчет
            if (videoDuration != null && estimatedProcessingTime != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 24,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Для вашего видео',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Длительность: ${_formatDuration(videoDuration!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Примерное время обработки: \n~ ${_formatDuration(estimatedProcessingTime!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Кнопка OK
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
