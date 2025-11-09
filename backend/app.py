"""
Backend API для обработки видео с фитнес-упражнениями на FastAPI.

Endpoints:
- POST /api/upload - загрузка видео для обработки
- GET /api/status/{task_id} - проверка статуса обработки
- GET /api/result/{task_id} - скачивание обработанного видео
- GET /api/health - проверка работоспособности
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Form
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Optional, Literal
import uuid
import asyncio
from pathlib import Path
import time
import logging
import aiofiles
from enum import Enum

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Создание приложения FastAPI
app = FastAPI(
    title="Video Processing API",
    description="API для обработки видео с фитнес-упражнениями",
    version="1.0.0"
)

# Настройка CORS для Flutter приложения
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Конфигурация
UPLOAD_FOLDER = Path('./uploads')
RESULTS_FOLDER = Path('./results')
ALLOWED_VIDEO_EXTENSIONS = {'.mp4', '.avi', '.mov', '.mkv', '.webm', '.flv', '.wmv'}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB

# Создаем необходимые директории
UPLOAD_FOLDER.mkdir(exist_ok=True)
RESULTS_FOLDER.mkdir(exist_ok=True)

# Хранилище задач (в продакшене использовать Redis или БД)
tasks: Dict[str, Dict] = {}

# Блокировка для обеспечения последовательной обработки
processing_lock = asyncio.Lock()
is_processing = False


# ============================================================================
# Pydantic модели для валидации и документации API
# ============================================================================

class TaskStatus(str, Enum):
    """Статус задачи обработки."""
    QUEUED = "queued"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class VideoResult(BaseModel):
    """Результат обработки видео."""
    exercise_type: str
    correctness: str
    confidence: float
    frame_count: int
    output_video: str


class TaskResponse(BaseModel):
    """Ответ с информацией о задаче."""
    task_id: str
    status: TaskStatus
    created_at: float
    updated_at: float
    result: Optional[VideoResult] = None
    error: Optional[str] = None


class UploadResponse(BaseModel):
    """Ответ при загрузке видео."""
    task_id: str
    status: TaskStatus
    message: str


class HealthResponse(BaseModel):
    """Ответ проверки здоровья сервера."""
    status: str
    message: str
    processing: bool


def is_video_file(filename: str) -> bool:
    """Проверка, является ли файл видео."""
    return Path(filename).suffix.lower() in ALLOWED_VIDEO_EXTENSIONS


async def process_video_task(task_id: str, video_path: str, rotation: Optional[int] = None):
    """
    Фоновая задача для обработки видео.
    
    Args:
        task_id: ID задачи
        video_path: путь к загруженному видео
        rotation: угол поворота (90, 180, 270 или None)
    """
    global is_processing
    
    try:
        # Обновляем статус
        tasks[task_id]['status'] = TaskStatus.PROCESSING.value
        tasks[task_id]['updated_at'] = time.time()
        logger.info(f"Начало обработки задачи {task_id}")
        
        # 🔧 ЗАГЛУШКА: Имитация работы модели
        # В реальности здесь будет вызов функций из model/project_root/src/
        logger.info(f"[MOCK] Обработка видео: {video_path}")
        
        # Симулируем длительную обработку (5-10 секунд)
        import random
        processing_time = random.uniform(5, 10)
        await asyncio.sleep(processing_time)
        
        # 🔧 ЗАГЛУШКА: Генерируем mock результаты
        mock_results = {
            'exercise_type': random.choice(['push_up', 'squat', 'long_jump']),
            'correctness': random.choice(['correct', 'incorrect', 'partial']),
            'confidence': round(random.uniform(0.7, 0.99), 2),
            'frame_count': random.randint(100, 300),
            'output_video': f'result_{task_id}.mp4'
        }
        
        # 🔧 ЗАГЛУШКА: Копируем исходное видео как результат (для демонстрации)
        # В реальности модель создаст новое обработанное видео
        import shutil
        result_video_path = RESULTS_FOLDER / mock_results['output_video']
        shutil.copy(video_path, result_video_path)
        
        logger.info(f"[MOCK] Результаты: {mock_results}")
        
        # 📝 В продакшене раскомментировать:
        # import shutil
        # from model.project_root.src.backend_interface import (
        #     process_video_with_rotation, 
        #     analyze_video_frames
        # )
        # 
        # # Обрабатываем видео и получаем кадры
        # frames_dir = process_video_with_rotation(video_path, rotation)
        # 
        # # Анализируем кадры (модель всегда возвращает .mp4)
        # results = analyze_video_frames(frames_dir, fps=30)
        # 
        # # Копируем результирующее видео в папку results
        # output_video_src = Path(results['output_video'])
        # output_video_dst = RESULTS_FOLDER / f'result_{task_id}.mp4'
        # shutil.copy(output_video_src, output_video_dst)
        # 
        # results['output_video'] = output_video_dst.name
        
        # Обновляем задачу с результатами
        tasks[task_id]['status'] = TaskStatus.COMPLETED.value
        tasks[task_id]['result'] = mock_results
        tasks[task_id]['updated_at'] = time.time()
        logger.info(f"Задача {task_id} успешно завершена")
        
    except Exception as e:
        logger.error(f"Ошибка при обработке задачи {task_id}: {str(e)}", exc_info=True)
        tasks[task_id]['status'] = TaskStatus.FAILED.value
        tasks[task_id]['error'] = str(e)
        tasks[task_id]['updated_at'] = time.time()
    
    finally:
        # Освобождаем блокировку
        global is_processing
        is_processing = False
        processing_lock.release()
        logger.info(f"Блокировка обработки освобождена")


@app.get("/api/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """
    Проверка работоспособности сервера.
    
    Returns:
        HealthResponse: Статус сервера и флаг обработки
    """
    return HealthResponse(
        status="ok",
        message="Server is running",
        processing=is_processing
    )


@app.post("/api/upload", response_model=UploadResponse, status_code=201, tags=["Video"])
async def upload_video(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    rotation: Optional[int] = Form(None)
):
    """
    Загрузка видео для обработки.
    
    Args:
        file: Видеофайл (любой формат: mp4, avi, mov, mkv, webm, etc.)
        rotation: Угол поворота видео (90, 180 или 270 градусов)
    
    Returns:
        UploadResponse: ID задачи и статус
        
    Raises:
        HTTPException: При ошибке валидации или загрузки
    """
    # Валидация файла
    if not file.filename:
        raise HTTPException(status_code=400, detail="Empty filename")
    
    if not is_video_file(file.filename):
        raise HTTPException(
            status_code=400,
            detail=f"File type not allowed. Allowed extensions: {', '.join(ALLOWED_VIDEO_EXTENSIONS)}"
        )
    
    # Валидация параметра rotation
    if rotation is not None and rotation not in [90, 180, 270]:
        raise HTTPException(
            status_code=400,
            detail="Rotation must be 90, 180, or 270"
        )
    
    try:
        # Генерируем уникальный ID задачи
        task_id = str(uuid.uuid4())
        
        # Определяем расширение и безопасное имя файла
        file_ext = Path(file.filename).suffix.lower()
        safe_filename = f'{task_id}{file_ext}'
        video_path = UPLOAD_FOLDER / safe_filename
        
        # Асинхронно сохраняем файл
        async with aiofiles.open(video_path, 'wb') as out_file:
            content = await file.read()
            await out_file.write(content)
        
        file_size = video_path.stat().st_size
        logger.info(f"Видео загружено: {video_path} (размер: {file_size} байт)")
        
        # Создаем запись о задаче
        tasks[task_id] = {
            'id': task_id,
            'status': TaskStatus.QUEUED.value,
            'created_at': time.time(),
            'updated_at': time.time(),
            'video_path': str(video_path),
            'rotation': rotation,
            'filename': file.filename
        }
        
        # Пытаемся захватить блокировку для обработки
        if not processing_lock.locked():
            await processing_lock.acquire()
            global is_processing
            is_processing = True
            # Запускаем обработку в фоне
            background_tasks.add_task(process_video_task, task_id, str(video_path), rotation)
            logger.info(f"Обработка задачи {task_id} запущена немедленно")
        else:
            logger.info(f"Задача {task_id} поставлена в очередь")
        
        return UploadResponse(
            task_id=task_id,
            status=TaskStatus(tasks[task_id]['status']),
            message="Video uploaded successfully"
        )
        
    except Exception as e:
        logger.error(f"Ошибка при загрузке видео: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@app.get("/api/status/{task_id}", response_model=TaskResponse, tags=["Video"])
async def get_status(task_id: str):
    """
    Получение статуса обработки видео.
    
    Args:
        task_id: ID задачи, полученный при загрузке
    
    Returns:
        TaskResponse: Информация о задаче и её статусе
        
    Raises:
        HTTPException: Если задача не найдена
    """
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    
    # Формируем ответ
    response_data = {
        'task_id': task['id'],
        'status': task['status'],
        'created_at': task['created_at'],
        'updated_at': task['updated_at']
    }
    
    # Добавляем результат если обработка завершена
    if task['status'] == TaskStatus.COMPLETED.value:
        response_data['result'] = VideoResult(**task['result'])
    
    # Добавляем ошибку если обработка провалилась
    if task['status'] == TaskStatus.FAILED.value:
        response_data['error'] = task.get('error', 'Unknown error')
    
    return TaskResponse(**response_data)


@app.get("/api/result/{task_id}", response_class=FileResponse, tags=["Video"])
async def get_result(task_id: str):
    """
    Скачивание обработанного видео.
    
    Args:
        task_id: ID задачи
    
    Returns:
        FileResponse: Видеофайл в формате MP4
        
    Raises:
        HTTPException: Если задача не найдена, не завершена или файл отсутствует
    """
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    
    if task['status'] != TaskStatus.COMPLETED.value:
        raise HTTPException(
            status_code=400,
            detail=f"Task not completed. Current status: {task['status']}"
        )
    
    # Получаем путь к результирующему видео (всегда MP4)
    result_video = task['result']['output_video']
    video_path = RESULTS_FOLDER / result_video
    
    if not video_path.exists():
        raise HTTPException(status_code=404, detail="Result video not found")
    
    # Возвращаем видео с правильными заголовками для воспроизведения в браузере
    return FileResponse(
        path=str(video_path),
        media_type='video/mp4',
        filename=result_video,
        headers={
            'Content-Disposition': f'inline; filename="{result_video}"',
            'Accept-Ranges': 'bytes',
        }
    )


@app.get("/api/tasks", tags=["Debug"])
async def list_tasks():
    """
    Получение списка всех задач (для отладки).
    
    Returns:
        dict: Список всех задач с основной информацией
    """
    task_list = []
    for task_id, task in tasks.items():
        task_info = {
            'task_id': task_id,
            'status': task['status'],
            'created_at': task['created_at'],
            'updated_at': task['updated_at'],
            'filename': task['filename']
        }
        task_list.append(task_info)
    
    return {'tasks': task_list}


if __name__ == '__main__':
    import uvicorn
    
    logger.info("=" * 50)
    logger.info("🚀 Запуск FastAPI сервера...")
    logger.info("=" * 50)
    logger.info(f"📁 Upload folder: {UPLOAD_FOLDER.absolute()}")
    logger.info(f"📁 Results folder: {RESULTS_FOLDER.absolute()}")
    logger.info(f"🌐 API документация: http://localhost:8000/docs")
    logger.info(f"📖 ReDoc: http://localhost:8000/redoc")
    logger.info("=" * 50)
    
    # Запускаем сервер с uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
