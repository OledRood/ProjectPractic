# API для работы с видео

Модуль для взаимодействия с backend API обработки видео.

## 📁 Структура

```
lib/core/video/
├── models/
│   └── video_task.dart          # Модели данных (VideoTask, VideoResult, etc.)
├── services/
│   └── video_api_service.dart   # Сервис для работы с API
└── video_di.dart                 # Провайдеры Riverpod

lib/features/video/
└── screens/
    └── video_processing_example_screen.dart  # Пример использования
```

## 🚀 Использование

### 1. Базовое использование

```dart
import 'package:frontend_proj/core/video/services/video_api_service.dart';
import 'package:frontend_proj/core/video/models/video_task.dart';

// Создаем сервис
final service = VideoApiService();

// Проверяем доступность сервера
final isHealthy = await service.healthCheck();

// Загружаем видео
final uploadResponse = await service.uploadVideo(
  File('/path/to/video.mp4'),
  rotation: 90, // опционально
  onProgress: (progress) {
    print('Загружено: ${(progress * 100).toInt()}%');
  },
);

// Получаем ID задачи
final taskId = uploadResponse.taskId;

// Проверяем статус
final task = await service.getStatus(taskId);
print('Статус: ${task.status}');

// Скачиваем результат (когда status = completed)
await service.downloadResult(
  taskId,
  '/path/to/save/result.mp4',
  onProgress: (progress) {
    print('Скачано: ${(progress * 100).toInt()}%');
  },
);
```

### 2. Использование с Riverpod

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_proj/core/video/video_di.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем сервис через провайдер
    final service = ref.watch(videoApiServiceProvider);
    
    // Проверяем состояние сервера
    final serverHealth = ref.watch(serverHealthProvider);
    
    return serverHealth.when(
      data: (isHealthy) => Text(isHealthy ? 'Сервер доступен' : 'Сервер недоступен'),
      loading: () => CircularProgressIndicator(),
      error: (_, __) => Text('Ошибка подключения'),
    );
  }
}
```

### 3. Опрос статуса с интервалом

```dart
// Автоматически опрашивает статус каждые 2 секунды до завершения
await for (final task in service.pollStatus(taskId)) {
  print('Текущий статус: ${task.status}');
  
  if (task.status == TaskStatus.completed) {
    // Обработка завершена
    final result = task.result!;
    print('Упражнение: ${result.exerciseTypeName}');
    print('Корректность: ${result.correctnessName}');
    print('Уверенность: ${result.confidence}');
    break;
  }
  
  if (task.status == TaskStatus.failed) {
    // Произошла ошибка
    print('Ошибка: ${task.error}');
    break;
  }
}
```

## 📊 Модели данных

### VideoTask
Представляет задачу обработки видео.

```dart
class VideoTask {
  final String taskId;
  final TaskStatus status;  // queued, processing, completed, failed
  final DateTime createdAt;
  final DateTime updatedAt;
  final VideoResult? result;  // доступно только при status = completed
  final String? error;        // доступно только при status = failed
}
```

### VideoResult
Результат обработки видео.

```dart
class VideoResult {
  final String exerciseType;      // push_up, squat, long_jump
  final String correctness;       // correct, incorrect, partial
  final double confidence;        // 0.0 - 1.0
  final int frameCount;
  final String outputVideo;       // имя файла результата
  
  // Удобные геттеры
  String get exerciseTypeName;    // "Отжимания", "Приседания", etc.
  String get correctnessName;     // "Правильно", "Неправильно", etc.
}
```

### TaskStatus
Перечисление возможных статусов задачи.

```dart
enum TaskStatus {
  queued,      // в очереди
  processing,  // обрабатывается
  completed,   // завершено
  failed       // ошибка
}
```

## ⚙️ Конфигурация

В файле `lib/core/video/services/video_api_service.dart`:

```dart
const String BASE_URL = 'http://localhost:5000/api';
```

Измените `BASE_URL` для подключения к вашему серверу.

Для Android эмулятора используйте: `http://10.0.2.2:5000/api`
Для iOS симулятора используйте: `http://localhost:5000/api`
Для реального устройства: `http://YOUR_COMPUTER_IP:5000/api`

## 🧪 Тестовый экран

Для быстрого тестирования API используйте готовый экран:

```dart
import 'package:frontend_proj/features/video/screens/video_processing_example_screen.dart';

// В роутере или Navigator
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => VideoProcessingExampleScreen()),
);
```

Этот экран позволяет:
- ✅ Проверить подключение к серверу
- ✅ Выбрать видеофайл
- ✅ Загрузить видео с отслеживанием прогресса
- ✅ Отслеживать статус обработки в реальном времени
- ✅ Просмотреть результаты анализа
- ✅ Скачать обработанное видео

## 🔧 Обработка ошибок

Все методы могут выбросить `VideoApiException`:

```dart
try {
  final response = await service.uploadVideo(file);
} on VideoApiException catch (e) {
  print('Ошибка API: ${e.message}');
  print('Код статуса: ${e.statusCode}');
} catch (e) {
  print('Неизвестная ошибка: $e');
}
```

## 📝 Примеры ошибок

- `"Файл не найден"` - файл не существует
- `"Файл слишком большой (макс. 100MB)"` - превышен лимит размера
- `"Угол поворота должен быть 90, 180 или 270"` - неверный параметр rotation
- `"Task not found"` - задача с таким ID не найдена
- `"Task not completed"` - попытка скачать результат до завершения обработки
- `"Ошибка сети: ..."` - проблемы с подключением

## 🎯 Best Practices

1. **Всегда проверяйте доступность сервера** перед основными операциями:
```dart
if (await service.healthCheck()) {
  // Сервер доступен
}
```

2. **Используйте pollStatus** вместо ручного опроса:
```dart
// ✅ Хорошо
await for (final task in service.pollStatus(taskId)) {
  // обработка
}

// ❌ Плохо
while (true) {
  final task = await service.getStatus(taskId);
  await Future.delayed(Duration(seconds: 2));
}
```

3. **Обрабатывайте все возможные статусы**:
```dart
switch (task.status) {
  case TaskStatus.queued:
    // показать "В очереди"
  case TaskStatus.processing:
    // показать прогресс
  case TaskStatus.completed:
    // показать результат
  case TaskStatus.failed:
    // показать ошибку
}
```

4. **Показывайте прогресс пользователю**:
```dart
await service.uploadVideo(
  file,
  onProgress: (progress) {
    setState(() {
      uploadProgress = progress;
    });
  },
);
```

5. **Используйте Riverpod для управления состоянием**:
```dart
final service = ref.watch(videoApiServiceProvider);
```
