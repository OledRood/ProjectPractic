"""
Модуль для интеграции с моделью обработки видео.
"""
import sys
from pathlib import Path
import logging
import cv2
import torch
from ultralytics import YOLO
import shutil

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Путь к корневой директории модели
CURRENT_DIR = Path(__file__).parent
MODEL_ROOT = CURRENT_DIR.parent / 'model' / 'project_root'
MODEL_PATH = MODEL_ROOT / 'yolo11n.pt'

class ModelProcessor:
    def __init__(self):
        """Инициализация модели."""
        try:
            # Проверяем наличие CUDA
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
            logger.info(f"Using device: {self.device}")
            
            # Загружаем модель
            self.model = YOLO(str(MODEL_PATH))
            logger.info("Model loaded successfully")
            
        except Exception as e:
            logger.error(f"Error initializing model: {str(e)}")
            raise

    async def process_video(self, input_path: Path, output_path: Path, progress_callback=None) -> dict:
        """
        Обработка видео с использованием модели.
        
        Args:
            input_path (Path): Путь к входному видео
            output_path (Path): Путь для сохранения обработанного видео
            progress_callback (callable): Функция обратного вызова для отслеживания прогресса
                Принимает два аргумента: stage (str) и progress (float)
            
        Returns:
            dict: Результаты обработки видео
        """
        try:
            # Считаем общее количество кадров для прогресса
            cap = cv2.VideoCapture(str(input_path))
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()

            # Получаем результаты от модели
            confidence_scores = []
            processed_frames = 0

            if progress_callback:
                progress_callback("Подготовка модели", 0.1)

            # Создаем временную директорию для результатов модели
            temp_output_dir = output_path.parent / f"temp_{output_path.stem}"
            temp_output_dir.mkdir(exist_ok=True)
            
            # Получаем результаты от модели
            results = []
            for result in self.model(str(input_path), save=True, project=str(temp_output_dir), name=input_path.stem, stream=True):
                results.append(result)
                processed_frames += 1

                if result.boxes is not None and len(result.boxes) > 0:
                    confidence_scores.extend(result.boxes.conf.cpu().numpy())

                if progress_callback:
                    progress_callback(
                        f"Обработка кадра {processed_frames}/{total_frames}",
                        0.1 + (0.8 * processed_frames / total_frames)
                    )
            
            # Перемещаем результат в нужное место
            result_file = temp_output_dir / input_path.stem / f"{input_path.stem}.mp4"
            if result_file.exists():
                shutil.move(str(result_file), str(output_path))
                shutil.rmtree(str(temp_output_dir), ignore_errors=True)
            
            if progress_callback:
                progress_callback("Завершение обработки", 0.9)

            # Формируем результат
            avg_confidence = float(sum(confidence_scores) / len(confidence_scores)) if confidence_scores else 0.0
            
            if progress_callback:
                progress_callback("Готово!", 1.0)

            return {
                "exercise_type": "detected_exercise",  # В будущем можно добавить классификацию упражнения
                "correctness": "good" if avg_confidence > 0.7 else "needs_improvement",
                "confidence": avg_confidence,
                "frame_count": len(results)
            }
            
        except Exception as e:
            logger.error(f"Error processing video: {str(e)}")
            raise

# Создаем глобальный экземпляр обработчика
model_processor = None

def get_model_processor() -> ModelProcessor:
    """
    Получение глобального экземпляра обработчика модели.
    """
    global model_processor
    if model_processor is None:
        model_processor = ModelProcessor()
    return model_processor