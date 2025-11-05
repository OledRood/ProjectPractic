import os
import argparse
import logging
import csv
from pathlib import Path
import sys
import yaml

from fitness_pose_extraction import FitnessPoseExtractor
from fitness_skeleton_visualization import visualize as visualize_skeleton
from exercise_recognition_model import train_exercise_classifier, infer_exercise
from merge_frames_to_video import merge_frames_to_video

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

def label_data(csv_path: str, exercise_type: str) -> str:
    """Размечает данные в CSV файле для обучения модели."""
    logger.info(f"Разметка данных в {csv_path} как {exercise_type}")
    
    # Создаем новый CSV с разметкой
    labeled_csv = Path(csv_path).parent / f"labeled_{Path(csv_path).name}"
    with open(csv_path, 'r') as f_in, open(labeled_csv, 'w', newline='') as f_out:
        reader = csv.DictReader(f_in)
        fieldnames = list(reader.fieldnames) + ['exercise_type', 'is_correct']
        writer = csv.DictWriter(f_out, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            row['exercise_type'] = exercise_type
            row['is_correct'] = 1  # Предполагаем правильное выполнение
            writer.writerow(row)
    
    logger.info(f"Данные размечены и сохранены в {labeled_csv}")
    return str(labeled_csv)

def process_frames(frames_dir: str, yolo_model: str = 'yolov8n-pose.pt', config_path: str = None, exercise_type: str = None) -> str:
    project_root = get_project_root()
    frames_dir = Path(frames_dir)
    if not frames_dir.exists():
        raise FileNotFoundError(f"Папка с кадрами не найдена: {frames_dir}")

    video_name = frames_dir.name
    output_csv = project_root / 'data' / 'annotations' / f'{video_name}_pose_data.csv'

    if config_path is None:
        config_path = str(project_root / 'config/config.yaml')
    processor = FitnessPoseExtractor(yolo_model_path=str(project_root / 'models' / yolo_model), config_path=config_path)
    logger.info(f"Извлечение поз из кадров в {output_csv}...")
    processor.process_video_frames(str(frames_dir), str(output_csv))

    return str(output_csv)

def visualize_and_infer(csv_path: str, frames_dir: str, output_dir: str = None, clean_canvas: bool = False, sample_size: int = None):
    logger.info(f"Визуализация и анализ упражнений из {csv_path}...")
    
    processed_frames_dir = Path(output_dir) / "processed_frames"
    processed_frames_dir.mkdir(parents=True, exist_ok=True)
    
    config_path = str(get_project_root() / 'config/config.yaml')
    model_path = str(get_project_root() / 'models/exercise_classifier.pth')
    
    # Проверка наличия обученной модели
    if not os.path.exists(model_path):
        logger.error("Модель не найдена. Пожалуйста, сначала обучите модель на размеченных данных.")
        raise FileNotFoundError(f"Модель не найдена по пути: {model_path}")
    
    # Визуализация и инференс после обучения
    visualize_skeleton(
        csv_path=csv_path,
        output_dir=str(processed_frames_dir),
        clean_canvas=clean_canvas,
        sample_size=sample_size
    )
    
    predictions = infer_exercise(csv_path, config_path)
    if predictions:  # Только если есть предсказания (не unknown)
        logger.info("Предсказания упражнений:")
        for pred in predictions:
            logger.info(f"Frame {pred['frame_id']}: {pred['exercise_type']} - {pred['correctness']}")
        
    return str(processed_frames_dir)

def assemble_video(frames_dir: str, output_video: str, fps: int = 30):
    frames_dir = Path(frames_dir)
    output_video = Path(output_video)
    logger.info(f"Сборка кадров из {frames_dir} в видео {output_video}...")
    merge_frames_to_video(frames_dir, output_video, fps)

def main():
    parser = argparse.ArgumentParser(description='Пайплайн определения упражнений')
    parser.add_argument('--frames_dir', type=str, required=True, help='Путь к папке с нарезанными кадрами')
    parser.add_argument('--yolo_model', type=str, default='yolov8n-pose.pt', help='Имя файла модели YOLO')
    parser.add_argument('--process', action='store_true', help='Обработать кадры и извлечь позы в CSV')
    parser.add_argument('--visualize', action='store_true', help='Визуализировать скелеты и предсказать упражнения')
    parser.add_argument('--assemble', action='store_true', help='Собрать визуализированные кадры в видео')
    parser.add_argument('--exercise_type', type=str, choices=['pushup', 'squat', 'long_jump'], 
                       help='Тип упражнения для разметки данных')
    parser.add_argument('--fps', type=int, default=30, help='FPS для выходного видео')
    parser.add_argument('--output_video', type=str, default='data/visualizations/output_video.mp4', help='Путь к выходному видео')
    parser.add_argument('--clean_visuals', action='store_true', help='Рисовать на белом фоне')
    parser.add_argument('--sample_size', type=int, default=None, help='Количество образцов для визуализации')
    parser.add_argument('--log_level', default='INFO', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'], help='Уровень логирования')

    args = parser.parse_args()
    logger.setLevel(args.log_level)

    try:
        frames_dir = (get_project_root() / args.frames_dir).resolve()
        if not frames_dir.exists():
            raise FileNotFoundError(f"Папка с кадрами не найдена: {frames_dir}")

        video_name = frames_dir.name
        csv_path = str(get_project_root() / 'data' / 'annotations' / f'{video_name}_pose_data.csv')
        processed_frames_dir = None

        if args.process:
            csv_path = process_frames(str(frames_dir), args.yolo_model)
            if args.exercise_type:
                labeled_csv_path = label_data(csv_path, args.exercise_type)
                train_exercise_classifier(labeled_csv_path)
                csv_path = labeled_csv_path

        if args.visualize:
            if not os.path.exists(csv_path):
                # Если CSV не существует, создаем его
                csv_path = process_frames(str(frames_dir), args.yolo_model)
            
            processed_frames_dir = visualize_and_infer(
                csv_path,
                str(frames_dir),
                output_dir=str(get_project_root() / 'data' / 'visualizations'),
                clean_canvas=args.clean_visuals,
                sample_size=args.sample_size
            )

        if args.assemble and processed_frames_dir:
            assemble_video(processed_frames_dir, str(get_project_root() / args.output_video), args.fps)

        logger.info("Пайплайн успешно завершен")
        sys.exit(0)

    except Exception as e:
        logger.error(f"Сбой пайплайна: {str(e)}", exc_info=True)
        sys.exit(1)

if __name__ == "__main__":
    main()