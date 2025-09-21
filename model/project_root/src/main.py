import os
import argparse
import logging
from pathlib import Path
from typing import List, Tuple, Optional
import sys

from detect_and_annotate import PoseProcessor
from visualize_skeleton_from_detailed_csv import visualize as visualize_skeleton
from cnn_model import train_pose_classifier as train_cnn_classifier

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('pipeline.log')
    ]
)
logger = logging.getLogger(__name__)

def get_project_root() -> Path:
    return Path(__file__).parent.parent

def validate_dataset_structure(dataset_path: Path, required_classes: Optional[List[str]] = None) -> bool:
    if not dataset_path.exists():
        logger.error(f"Директория датасета не найдена: {dataset_path}")
        return False

    if required_classes is None:
        required_classes = ['standing', 'sitting', 'lying']
    
    present_classes = {f.name for f in dataset_path.iterdir() if f.is_dir()}
    missing_classes = set(required_classes) - present_classes
    
    if missing_classes:
        logger.warning(f"Отсутствуют классы: {missing_classes}. Продолжаем с доступными классами.")
    
    has_images = False
    for class_name in present_classes:
        class_dir = dataset_path / class_name
        if any(file.suffix.lower() in ['.jpg', '.jpeg', '.png'] for file in class_dir.glob('**/*')):
            has_images = True
        else:
            logger.warning(f"Изображения не найдены в директории класса: {class_dir}")
    
    if not has_images:
        logger.error("Изображения не найдены ни в одной директории класса")
        return False

    return True

def process_dataset(
    dataset_root: Path = None,
    yolo_model: str = 'yolov8n-pose.pt',
    required_classes: Optional[List[str]] = None
) -> List[Tuple[str, str]]:
    project_root = get_project_root()
    dataset_root = dataset_root or project_root / 'data' / 'dataset'

    if not validate_dataset_structure(dataset_root, required_classes):
        raise ValueError("Некорректная структура датасета")

    output_dir = project_root / 'data' / 'annotations'
    output_dir.mkdir(parents=True, exist_ok=True)

    processor = PoseProcessor(yolo_model_path=str(project_root / 'models' / yolo_model))
    csv_paths = []

    for class_dir in dataset_root.iterdir():
        if not class_dir.is_dir():
            continue
            
        class_name = class_dir.name
        if required_classes and class_name not in required_classes:
            continue

        output_csv = output_dir / f'{class_name}_annotations.csv'

        logger.info(f"Обработка изображений класса {class_name}...")
        try:
            processor.process_class_directory(str(class_dir), str(output_csv))
            if output_csv.exists():
                csv_paths.append((class_name, str(output_csv)))
                logger.info(f"Аннотации сохранены в {output_csv}")
            else:
                logger.warning(f"Аннотации для {class_name} не созданы")
        except Exception as e:
            logger.error(f"Ошибка обработки {class_name}: {str(e)}")
            continue

    if not csv_paths:
        raise RuntimeError("CSV файлы не были созданы")

    return csv_paths

def visualize_annotations(
    csv_paths: List[Tuple[str, str]],
    clean_canvas: bool = False,
    live: bool = False,
    sample_size: int = 10
) -> None:
    project_root = get_project_root()
    vis_output_dir = project_root / 'data' / 'visualizations'

    if live:
        logger.info("Запуск визуализации в реальном времени с веб-камеры...")
        visualize_skeleton(live=True)
        return

    for class_name, csv_path in csv_paths:
        output_dir = vis_output_dir / class_name
        output_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Визуализация скелетов для {class_name}... (чистый фон={clean_canvas}, выборка={sample_size})")
        try:
            visualize_skeleton(
                csv_path=csv_path,
                output_dir=str(output_dir),
                clean_canvas=clean_canvas,
                sample_size=sample_size
            )
            logger.info(f"Визуализации сохранены в {output_dir}")
        except Exception as e:
            logger.error(f"Ошибка визуализации {class_name}: {str(e)}")
            continue

def train_model(
    csv_paths: List[Tuple[str, str]],
    model_type: str = 'cnn',
    epochs: int = 30,
    batch_size: int = 32,
    learning_rate: float = 0.001
) -> str:
    project_root = get_project_root()
    models_dir = project_root / 'models'
    models_dir.mkdir(parents=True, exist_ok=True)

    if model_type == 'cnn':
        model_save_path = models_dir / 'pose_classifier.pth'
        logger.info(f"Обучение модели {model_type} на {epochs} эпох (размер батча={batch_size}, lr={learning_rate})...")
        train_cnn_classifier(
            csv_paths=[path for _, path in csv_paths],
            model_save_path=str(model_save_path),
            epochs=epochs,
            batch_size=batch_size,
            learning_rate=learning_rate
        )
    else:
        raise ValueError(f"Неподдерживаемый тип модели: {model_type}")

    logger.info(f"Модель сохранена в {model_save_path}")
    return str(model_save_path)

def main():
    parser = argparse.ArgumentParser(description='Пайплайн оценки человеческой позы')
    parser.add_argument('--dataset', type=str, default=None, help='Путь к директории датасета')
    parser.add_argument('--classes', nargs='+', default=['standing', 'sitting', 'lying'], 
                       help='Список имен классов для обработки')
    parser.add_argument('--yolo_model', type=str, default='yolov8n-pose.pt', 
                       help='Имя файла модели YOLO в директории models/')
    
    parser.add_argument('--process', action='store_true', help='Обработать датасет и создать аннотации')
    parser.add_argument('--visualize', action='store_true', help='Визуализировать скелеты из аннотаций')
    parser.add_argument('--train', action='store_true', help='Обучить модель после обработки')
    
    parser.add_argument('--clean_visuals', action='store_true', help='Рисовать на белом фоне')
    parser.add_argument('--live', action='store_true', help='Использовать веб-камеру для визуализации в реальном времени')
    parser.add_argument('--sample_size', type=int, default=10, 
                       help='Количество образцов для визуализации на класс (0 для всех)')
    
    parser.add_argument('--epochs', type=int, default=30, help='Количество эпох обучения')
    parser.add_argument('--batch_size', type=int, default=32, help='Размер батча для обучения')
    parser.add_argument('--learning_rate', type=float, default=0.001, help='Скорость обучения')
    parser.add_argument('--model_type', choices=['cnn'], default='cnn', 
                       help='Тип модели для обучения')
    
    parser.add_argument('--log_level', default='INFO', 
                       choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'], help='Уровень логирования')
    
    args = parser.parse_args()
    logger.setLevel(args.log_level)

    try:
        csv_files = []
        
        if args.process or args.train:
            csv_files = process_dataset(
                dataset_root=Path(args.dataset) if args.dataset else None,
                yolo_model=args.yolo_model,
                required_classes=args.classes
            )

        if args.visualize or args.live:
            visualize_annotations(
                csv_files,
                clean_canvas=args.clean_visuals,
                live=args.live,
                sample_size=args.sample_size
            )

        if args.train:
            model_path = train_model(
                csv_files,
                model_type=args.model_type,
                epochs=args.epochs,
                batch_size=args.batch_size,
                learning_rate=args.learning_rate
            )
            logger.info(f"Обучение завершено. Модель сохранена в {model_path}")

        logger.info("Пайплайн успешно завершен")
        sys.exit(0)
        
    except Exception as e:
        logger.error(f"Сбой пайплайна: {str(e)}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()