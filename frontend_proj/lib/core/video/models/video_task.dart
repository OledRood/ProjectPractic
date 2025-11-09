/// Модель задачи обработки видео
class VideoTask {
  final String taskId;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VideoResult? result;
  final String? error;
  final double? progress; // Прогресс обработки (0.0 - 1.0)
  final String? stage; // Текущий этап обработки

  VideoTask({
    required this.taskId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.result,
    this.error,
    this.progress,
    this.stage,
  });

  factory VideoTask.fromJson(Map<String, dynamic> json) {
    return VideoTask(
      taskId: json['task_id'] as String,
      status: TaskStatus.fromString(json['status'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] as num).toInt() * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updated_at'] as num).toInt() * 1000,
      ),
      result: json['result'] != null
          ? VideoResult.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
      progress: json['progress'] != null
          ? (json['progress'] as num).toDouble()
          : null,
      stage: json['stage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'status': status.value,
      'created_at': createdAt.millisecondsSinceEpoch / 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch / 1000,
      if (result != null) 'result': result!.toJson(),
      if (error != null) 'error': error,
    };
  }
}

/// Статус задачи
enum TaskStatus {
  queued('queued'),
  processing('processing'),
  completed('completed'),
  failed('failed');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.queued,
    );
  }
}

/// Результат обработки видео
class VideoResult {
  final String exerciseType;
  final String correctness;
  final double confidence;
  final int frameCount;
  final String outputVideo;

  VideoResult({
    required this.exerciseType,
    required this.correctness,
    required this.confidence,
    required this.frameCount,
    required this.outputVideo,
  });

  factory VideoResult.fromJson(Map<String, dynamic> json) {
    return VideoResult(
      exerciseType: json['exercise_type'] as String,
      correctness: json['correctness'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      frameCount: json['frame_count'] as int,
      outputVideo: json['output_video'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_type': exerciseType,
      'correctness': correctness,
      'confidence': confidence,
      'frame_count': frameCount,
      'output_video': outputVideo,
    };
  }

  /// Получение читаемого названия упражнения
  String get exerciseTypeName {
    switch (exerciseType) {
      case 'push_up':
        return 'Отжимания';
      case 'squat':
        return 'Приседания';
      case 'long_jump':
        return 'Прыжок в длину';
      default:
        return exerciseType;
    }
  }

  /// Получение читаемого статуса корректности
  String get correctnessName {
    switch (correctness) {
      case 'correct':
        return 'Правильно';
      case 'incorrect':
        return 'Неправильно';
      case 'partial':
        return 'Частично правильно';
      default:
        return correctness;
    }
  }
}

/// Ответ при загрузке видео
class UploadResponse {
  final String taskId;
  final TaskStatus status;
  final String message;

  UploadResponse({
    required this.taskId,
    required this.status,
    required this.message,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      taskId: json['task_id'] as String,
      status: TaskStatus.fromString(json['status'] as String),
      message: json['message'] as String,
    );
  }
}
