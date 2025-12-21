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

/// Результат обработки видео (данные от модели)
class VideoResult {
  /// Статус обработки: "ok" или "error"
  final String status;
  
  /// Тип упражнения: "pushup", "pullup", "unknown"
  final String? exercise;
  
  /// Уверенность модели в определении упражнения (0-100%)
  final double? confidence;
  
  /// Список проблем с техникой (пустой = хорошая техника)
  final List<String> techniqueIssues;
  
  /// Метрики углов: elbow_angle, torso_angle, knee_angle, shoulders_high
  final Map<String, dynamic> metrics;
  
  /// Путь к обработанному видео
  final String? outputVideo;
  
  /// Текст ошибки (если status == "error")
  final String? error;

  VideoResult({
    required this.status,
    this.exercise,
    this.confidence,
    this.techniqueIssues = const [],
    this.metrics = const {},
    this.outputVideo,
    this.error,
  });

  factory VideoResult.fromJson(Map<String, dynamic> json) {
    return VideoResult(
      status: json['status'] as String? ?? 'ok',
      exercise: json['exercise'] as String?,
      confidence: json['confidence'] != null 
          ? (json['confidence'] as num).toDouble() 
          : null,
      techniqueIssues: json['technique_issues'] != null
          ? List<String>.from(json['technique_issues'] as List)
          : const [],
      metrics: json['metrics'] != null
          ? Map<String, dynamic>.from(json['metrics'] as Map)
          : const {},
      outputVideo: json['output_video'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (exercise != null) 'exercise': exercise,
      if (confidence != null) 'confidence': confidence,
      'technique_issues': techniqueIssues,
      'metrics': metrics,
      if (outputVideo != null) 'output_video': outputVideo,
      if (error != null) 'error': error,
    };
  }

  /// Техника хорошая (нет проблем)
  bool get isGoodTechnique => techniqueIssues.isEmpty && status == 'ok';
  
  /// Есть ошибка обработки
  bool get hasError => status == 'error';

  /// Получение читаемого названия упражнения
  String get exerciseDisplayName {
    switch (exercise) {
      case 'pushup':
        return 'Отжимания';
      case 'pullup':
        return 'Подтягивания';
      case 'unknown':
        return 'Не определено';
      default:
        return exercise ?? 'Не определено';
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
