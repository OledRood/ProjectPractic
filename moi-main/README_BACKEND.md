# Backend API для Анализа Упражнений

## Введение

**`src/backend_api.py`** содержит единственную функцию для интеграции в будущий бэкенд:

```python
analyze_video_for_backend(video_path: str, confidence_threshold: float = 0.7) -> Dict
```

Функция скрывает всю внутреннюю сложность pipeline'а и возвращает только **важные для бэкенда данные**.

## API Функция

### `analyze_video_for_backend(video_path, confidence_threshold=0.7)`

**Параметры:**
- `video_path` (str): путь к видео-файлу
- `confidence_threshold` (float): минимальная уверенность (0.0-1.0)

**Возвращает:**
```python
{
    "status": "ok" | "error",
    "exercise": "pushup" | "pullup",           # только если status == "ok"
    "confidence": 98.5,                        # процент 0-100
    "technique_issues": [...],                 # список проблем техники
    "metrics": {                               # измеренные углы
        "elbow_angle": 42.55,
        "torso_angle": 135.55,
        ...
    },
    "error": None | "error message"            # только если status == "error"
}
```

## Примеры использования

### Python-код для бэкенда

```python
from src.backend_api import analyze_video_for_backend

# Анализировать видео
result = analyze_video_for_backend("/path/to/video.mp4")

# Проверить статус
if result["status"] == "ok":
    exercise = result["exercise"]
    confidence = result["confidence"]
    issues = result["technique_issues"]
    metrics = result["metrics"]
    print(f"Упражнение: {exercise} ({confidence}%)")
else:
    error = result["error"]
    print(f"Ошибка: {error}")
```

### Командная строка (для тестирования)

```bash
cd project_root
python src/test_backend_api.py --video /path/to/video.mp4
```

**Вывод:**
```
================================================================================
📹 Analyzing: video5.mp4
================================================================================
✅ Status: OK

🏋️  Exercise: PUSHUP
💯 Confidence: 98.8%

⚠️  Technique Issues:
   • Увеличьте сгиб локтя до 80°
   • Выпрямите спину - держите её параллельно полу

📊 Metrics:
   elbow_angle: 42.55°
   torso_angle: 135.55°

================================================================================
```

## Что скрывает функция

Все это автоматически обрабатывается **внутри** `analyze_video_for_backend()`:

1. ✅ Нарезка видео на кадры
2. ✅ Извлечение поз (YOLOv8 Pose)
3. ✅ Создание скелетов (визуализация)
4. ✅ BiLSTM классификация упражнения
5. ✅ Валидация техники выполнения
6. ✅ Подавление лишних логов

**Бэкенду нужно знать только о самой функции** — остальное это её внутренние детали.

## Структура данных в `result["metrics"]`

```python
{
    "elbow_angle": float,          # угол локтя в градусах
    "torso_angle": float,          # угол туловища в градусах
    "knee_angle": float,           # угол коленей в градусах
    "shoulders_high": bool,        # плечи выше локтей (для pullup)
}
```

**Примечание:** не все метрики всегда присутствуют (зависит от упражнения и качества обнаружения скелета).

## Обработка ошибок

```python
result = analyze_video_for_backend("/nonexistent/video.mp4")

if result["status"] == "error":
    print(f"Ошибка анализа: {result['error']}")
    # Результат содержит:
    # - status: "error"
    # - exercise: None
    # - confidence: None
    # - technique_issues: []
    # - metrics: {}
    # - error: "файл не найден" или другое описание ошибки
```

## Интеграция в FastAPI / Flask

### FastAPI пример

```python
from fastapi import FastAPI, File, UploadFile
from backend_api import analyze_video_for_backend
import tempfile
from pathlib import Path

app = FastAPI()

@app.post("/analyze")
async def analyze_video(file: UploadFile):
    # Сохранить загруженный файл временно
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name
    
    try:
        # Вызвать функцию бэкенда
        result = analyze_video_for_backend(tmp_path)
        return result
    finally:
        # Очистить временный файл
        Path(tmp_path).unlink()
```

### Flask пример

```python
from flask import Flask, request, jsonify
from backend_api import analyze_video_for_backend
import tempfile
from pathlib import Path

app = Flask(__name__)

@app.route("/analyze", methods=["POST"])
def analyze_video():
    if "file" not in request.files:
        return jsonify({"status": "error", "error": "No file"}), 400
    
    file = request.files["file"]
    
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        file.save(tmp.name)
        tmp_path = tmp.name
    
    try:
        result = analyze_video_for_backend(tmp_path)
        return jsonify(result)
    finally:
        Path(tmp_path).unlink()
```

## Логирование

Функция автоматически **подавляет verbose логи** из внутренних модулей во время анализа, чтобы вывод был чистым.

Если нужны подробные логи для дебага:
1. Удалить вызовы `suppress_internal_logs()` / `restore_internal_logs()`
2. Или вручную настроить логирование перед вызовом функции

## Тестирование

```bash
# Быстрый тест с локальным видео
python src/test_backend_api.py --video data/dataset/video/pushups/pushup_sample.mp4

# Тест с файлом
python src/test_backend_api.py --video /path/to/your/video.mp4
```

## Требования

- Python 3.9+
- Все зависимости из `src/requirements.txt`
- Модели: `models/exercise_classifier.pth`, `models/yolov8n-pose.pt`

## Заключение

**Бэкенд-разработчик должен знать только это:**

```python
from backend_api import analyze_video_for_backend

result = analyze_video_for_backend("video.mp4")
# ... работать с result['exercise'], result['confidence'], result['technique_issues']
```

Всё остальное — это деталь реализации.
