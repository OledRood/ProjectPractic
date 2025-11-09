import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:frontend_proj/core/video/models/video_task.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// 🔧 КОНФИГУРАЦИЯ
/// ============================================================================
/// Измените BASE_URL для подключения к вашему серверу
/// FastAPI сервер работает на порту 8000
const String BASE_URL = 'http://localhost:8000/api';

/// Исключение при работе с API
class VideoApiException implements Exception {
  final String message;
  final int? statusCode;

  VideoApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'VideoApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Сервис для работы с API обработки видео
class VideoApiService {
  final Dio _dio;
  final String baseUrl;

  VideoApiService({String? baseUrl})
    : baseUrl = baseUrl ?? BASE_URL,
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? BASE_URL,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          // sendTimeout убран из BaseOptions, т.к. в Web это вызывает предупреждение для GET запросов
          // Для POST запросов с телом будем указывать sendTimeout явно
        ),
      ) {
    // Добавляем интерцепторы для логирования (только в debug режиме)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  /// Проверка работоспособности сервера
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200 && response.data['status'] == 'ok';
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Загрузка видео на сервер
  ///
  /// [videoFile] - файл видео для загрузки
  /// [rotation] - угол поворота видео (90, 180, 270 или null)
  /// [onProgress] - callback для отслеживания прогресса загрузки (0.0 - 1.0)
  Future<UploadResponse> uploadVideo(
    File videoFile, {
    int? rotation,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Проверяем существование файла
      if (!await videoFile.exists()) {
        throw VideoApiException('Файл не найден');
      }

      // Проверяем размер файла (максимум 100MB)
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        throw VideoApiException('Файл слишком большой (макс. 100MB)');
      }

      // Проверяем параметр rotation
      if (rotation != null && ![90, 180, 270].contains(rotation)) {
        throw VideoApiException('Угол поворота должен быть 90, 180 или 270');
      }

      // Формируем multipart/form-data запрос
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
        if (rotation != null) 'rotation': rotation.toString(),
      });

      // Отправляем запрос с отслеживанием прогресса
      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5), // Только для загрузки файлов
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 201) {
        return UploadResponse.fromJson(response.data);
      } else {
        throw VideoApiException(
          'Ошибка загрузки: ${response.data['error'] ?? 'Unknown error'}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['error'] ?? 'Unknown error';
        throw VideoApiException(errorMessage, e.response?.statusCode);
      } else {
        throw VideoApiException('Ошибка сети: ${e.message}');
      }
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException('Неизвестная ошибка: $e');
    }
  }

  /// Загрузка видео на сервер из байтов (для Web)
  ///
  /// [videoBytes] - байты видео файла
  /// [filename] - имя файла
  /// [rotation] - угол поворота видео (90, 180, 270 или null)
  /// [onProgress] - callback для отслеживания прогресса загрузки (0.0 - 1.0)
  Future<UploadResponse> uploadVideoBytes(
    Uint8List videoBytes,
    String filename, {
    int? rotation,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Проверяем размер файла (максимум 100MB)
      if (videoBytes.length > 100 * 1024 * 1024) {
        throw VideoApiException('Файл слишком большой (макс. 100MB)');
      }

      // Проверяем параметр rotation
      if (rotation != null && ![90, 180, 270].contains(rotation)) {
        throw VideoApiException('Угол поворота должен быть 90, 180 или 270');
      }

      // Формируем multipart/form-data запрос
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(videoBytes, filename: filename),
        if (rotation != null) 'rotation': rotation.toString(),
      });

      // Отправляем запрос с отслеживанием прогресса
      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5), // Только для загрузки файлов
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 201) {
        return UploadResponse.fromJson(response.data);
      } else {
        throw VideoApiException(
          'Ошибка загрузки: ${response.data['error'] ?? 'Unknown error'}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['error'] ?? 'Unknown error';
        throw VideoApiException(errorMessage, e.response?.statusCode);
      } else {
        throw VideoApiException('Ошибка сети: ${e.message}');
      }
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException('Неизвестная ошибка: $e');
    }
  }

  /// Получение статуса обработки видео
  ///
  /// [taskId] - ID задачи, полученный при загрузке
  Future<VideoTask> getStatus(String taskId) async {
    try {
      final response = await _dio.get('/status/$taskId');

      if (response.statusCode == 200) {
        return VideoTask.fromJson(response.data);
      } else {
        throw VideoApiException(
          'Ошибка получения статуса: ${response.data['error'] ?? 'Unknown error'}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['error'] ?? 'Unknown error';
        throw VideoApiException(errorMessage, e.response?.statusCode);
      } else {
        throw VideoApiException('Ошибка сети: ${e.message}');
      }
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException('Неизвестная ошибка: $e');
    }
  }

  /// Скачивание обработанного видео
  ///
  /// [taskId] - ID задачи
  /// [savePath] - путь для сохранения файла
  /// [onProgress] - callback для отслеживания прогресса скачивания (0.0 - 1.0)
  Future<void> downloadResult(
    String taskId,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _dio.download(
        '/result/$taskId',
        savePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        // Попытка прочитать JSON ошибку
        try {
          final errorMessage = e.response?.data['error'] ?? 'Unknown error';
          throw VideoApiException(errorMessage, e.response?.statusCode);
        } catch (_) {
          throw VideoApiException('Ошибка скачивания', e.response?.statusCode);
        }
      } else {
        throw VideoApiException('Ошибка сети: ${e.message}');
      }
    } catch (e) {
      if (e is VideoApiException) rethrow;
      throw VideoApiException('Неизвестная ошибка: $e');
    }
  }

  /// Опрос статуса с интервалом до завершения или ошибки
  ///
  /// [taskId] - ID задачи
  /// [onStatusUpdate] - callback при каждом обновлении статуса
  /// [pollInterval] - интервал опроса (по умолчанию 2 секунды)
  /// [maxAttempts] - максимальное количество попыток (по умолчанию 300 = 10 минут)
  Stream<VideoTask> pollStatus(
    String taskId, {
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 300,
  }) async* {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        final task = await getStatus(taskId);
        yield task;

        // Если задача завершена или провалилась, останавливаем опрос
        if (task.status == TaskStatus.completed ||
            task.status == TaskStatus.failed) {
          break;
        }

        // Ждем перед следующей попыткой
        await Future.delayed(pollInterval);
        attempts++;
      } catch (e) {
        debugPrint('Error polling status: $e');
        // Продолжаем попытки даже при ошибке
        await Future.delayed(pollInterval);
        attempts++;
      }
    }

    if (attempts >= maxAttempts) {
      throw VideoApiException('Превышено максимальное время ожидания');
    }
  }

  /// Отмена всех активных запросов
  void cancelAllRequests() {
    _dio.close(force: true);
  }
}
