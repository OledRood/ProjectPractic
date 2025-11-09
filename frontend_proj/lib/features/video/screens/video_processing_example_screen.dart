import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend_proj/core/video/services/video_api_service.dart';
import 'package:frontend_proj/core/video/models/video_task.dart';
import 'package:frontend_proj/core/video/video_di.dart';

/// Пример экрана для тестирования API
class VideoProcessingExampleScreen extends ConsumerStatefulWidget {
  const VideoProcessingExampleScreen({super.key});

  @override
  ConsumerState<VideoProcessingExampleScreen> createState() =>
      _VideoProcessingExampleScreenState();
}

class _VideoProcessingExampleScreenState
    extends ConsumerState<VideoProcessingExampleScreen> {
  File? _selectedFile;
  String? _currentTaskId;
  VideoTask? _currentTask;
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;
  bool _isProcessing = false;
  String? _errorMessage;

  /// Выбор видеофайла
  Future<void> _pickVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _errorMessage = null;
          _currentTask = null;
          _currentTaskId = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка выбора файла: $e';
      });
    }
  }

  /// Загрузка и обработка видео
  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Выберите файл';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });

    try {
      final service = ref.read(videoApiServiceProvider);

      // Шаг 1: Загрузка видео
      final uploadResponse = await service.uploadVideo(
        _selectedFile!,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _currentTaskId = uploadResponse.taskId;
      });

      // Шаг 2: Опрос статуса
      await for (final task in service.pollStatus(uploadResponse.taskId)) {
        setState(() {
          _currentTask = task;
        });

        // Если обработка завершена успешно
        if (task.status == TaskStatus.completed) {
          _showSuccessDialog(task);
          break;
        }

        // Если произошла ошибка
        if (task.status == TaskStatus.failed) {
          setState(() {
            _errorMessage = task.error ?? 'Ошибка обработки';
          });
          break;
        }
      }
    } on VideoApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Неизвестная ошибка: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Диалог с результатами
  void _showSuccessDialog(VideoTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обработка завершена'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Упражнение: ${task.result!.exerciseTypeName}'),
            const SizedBox(height: 8),
            Text('Корректность: ${task.result!.correctnessName}'),
            const SizedBox(height: 8),
            Text(
              'Уверенность: ${(task.result!.confidence * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 8),
            Text('Кадров: ${task.result!.frameCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadResult();
            },
            child: const Text('Скачать результат'),
          ),
        ],
      ),
    );
  }

  /// Скачивание результата
  Future<void> _downloadResult() async {
    if (_currentTaskId == null) return;

    setState(() {
      _downloadProgress = 0.0;
    });

    try {
      final service = ref.read(videoApiServiceProvider);

      // Используем временную директорию для примера
      final tempDir = Directory.systemTemp;
      final savePath = '${tempDir.path}/result_$_currentTaskId.mp4';

      await service.downloadResult(
        _currentTaskId!,
        savePath,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Видео сохранено: $savePath')));
      }
    } on VideoApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverHealth = ref.watch(serverHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Обработка видео'),
        actions: [
          // Индикатор состояния сервера
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: serverHealth.when(
              data: (isHealthy) => Icon(
                Icons.circle,
                color: isHealthy ? Colors.green : Colors.red,
                size: 16,
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) =>
                  const Icon(Icons.circle, color: Colors.red, size: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Информация о сервере
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: serverHealth.when(
                        data: (isHealthy) => Text(
                          isHealthy ? 'Сервер доступен' : 'Сервер недоступен',
                          style: TextStyle(
                            color: isHealthy ? Colors.green : Colors.red,
                          ),
                        ),
                        loading: () => const Text('Проверка сервера...'),
                        error: (_, __) => const Text(
                          'Ошибка подключения',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Выбор файла
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickVideoFile,
              icon: const Icon(Icons.video_library),
              label: const Text('Выбрать видео'),
            ),
            const SizedBox(height: 8),

            // Информация о выбранном файле
            if (_selectedFile != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выбран файл:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Кнопка обработки
            ElevatedButton.icon(
              onPressed: (_selectedFile != null && !_isProcessing)
                  ? _uploadAndProcess
                  : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Загрузить и обработать'),
            ),
            const SizedBox(height: 16),

            // Прогресс загрузки
            if (_isProcessing && _uploadProgress < 1.0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Загрузка: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  ),
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 16),
                ],
              ),

            // Статус обработки
            if (_currentTask != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusIcon(_currentTask!.status),
                          const SizedBox(width: 8),
                          Text(_buildStatusText(_currentTask!.status)),
                        ],
                      ),
                      if (_currentTask!.status == TaskStatus.processing)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),

            // Прогресс скачивания
            if (_downloadProgress > 0 && _downloadProgress < 1.0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Скачивание: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  ),
                  LinearProgressIndicator(value: _downloadProgress),
                ],
              ),

            // Ошибки
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.queued:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case TaskStatus.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TaskStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case TaskStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
    }
  }

  String _buildStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.queued:
        return 'В очереди';
      case TaskStatus.processing:
        return 'Обрабатывается...';
      case TaskStatus.completed:
        return 'Завершено';
      case TaskStatus.failed:
        return 'Ошибка';
    }
  }
}
