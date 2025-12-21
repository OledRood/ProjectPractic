import os
import csv
import cv2
import numpy as np
import argparse
import logging
import logging.handlers
from pathlib import Path
from collections import defaultdict
from sklearn.model_selection import train_test_split
from tqdm import tqdm

from fitness_pose_extraction import FitnessPoseExtractor
from exercise_recognition_model import ExerciseRecognitionModel
from video_to_frames import video_to_frames
import yaml

PROJECT_ROOT = Path(__file__).parent.parent
LOG_DIR = PROJECT_ROOT / 'logs'
LOG_DIR.mkdir(parents=True, exist_ok=True)

LOG_FILE = LOG_DIR / 'pipeline.log'

logger = logging.getLogger('FitnessPipeline')
logger.setLevel(logging.DEBUG)

# обработчик для файлов (все логи)
file_handler = logging.handlers.RotatingFileHandler(
    LOG_FILE,
    maxBytes=10*1024*1024,
    backupCount=5,
    encoding='utf-8'
)
file_handler.setLevel(logging.DEBUG)

# для консоли (только INFO и выше)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)

log_format = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

file_handler.setFormatter(log_format)
console_handler.setFormatter(log_format)

# Добавляем обработчики
logger.addHandler(file_handler)
logger.addHandler(console_handler)

logger.info("=" * 70)
logger.info("FITNESS PIPELINE STARTED")
logger.info(f"Log file: {LOG_FILE}")
logger.info("=" * 70)


PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / 'data'
MODELS_DIR = PROJECT_ROOT / 'models'
CONFIG_PATH = PROJECT_ROOT / 'config' / 'config.yaml'


SKELETON_CONNECTIONS = [
    ('LEFT_SHOULDER', 'RIGHT_SHOULDER'),
    ('LEFT_SHOULDER', 'LEFT_ELBOW'),
    ('LEFT_ELBOW', 'LEFT_WRIST'),
    ('RIGHT_SHOULDER', 'RIGHT_ELBOW'),
    ('RIGHT_ELBOW', 'RIGHT_WRIST'),
    ('LEFT_SHOULDER', 'LEFT_HIP'),
    ('RIGHT_SHOULDER', 'RIGHT_HIP'),
    ('LEFT_HIP', 'RIGHT_HIP'),
    ('LEFT_HIP', 'LEFT_KNEE'),
    ('LEFT_KNEE', 'LEFT_ANKLE'),
    ('RIGHT_HIP', 'RIGHT_KNEE'),
    ('RIGHT_KNEE', 'RIGHT_ANKLE'),
]

TORSO_POINTS = ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'RIGHT_HIP', 'LEFT_HIP']


def denormalize_keypoints(keypoints_norm, center_x, center_y, unit_length, image_shape, bbox):
    height, width = image_shape[:2]
    keypoints_scaled = {}
    x1, y1, x2, y2 = bbox
    bbox_width = x2 - x1
    bbox_height = y2 - y1
    
    for name, kp in keypoints_norm.items():
        x = x1 + (center_x + kp['x_norm'] * unit_length) * bbox_width
        y = y1 + (center_y + kp['y_norm'] * unit_length) * bbox_height
        x = max(x1, min(x, x2))
        y = max(y1, min(y, y2))
        keypoints_scaled[name] = (int(x), int(y))
    
    return keypoints_scaled


def draw_training_skeleton_frames(csv_path, frames_dir, output_dir):
 # рисование скелетов для обучения
    logger.info("\n рисую скелеты для датасета...")
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    data = defaultdict(list)
    meta = {}
    
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            img_path = row['image_path']
            data[img_path].append({
                'landmark': row['landmark'],
                'x_norm': float(row['x_norm']),
                'y_norm': float(row['y_norm']),
                'visibility': float(row['visibility'])
            })
            if img_path not in meta:
                meta[img_path] = {
                    'center_x': float(row['center_x']),
                    'center_y': float(row['center_y']),
                    'unit_length': float(row['unit_length']),
                    'bbox': eval(row['bbox'])
                }
    
    img_paths = sorted(list(data.keys()))
    
    for img_path in img_paths:
        if not Path(img_path).exists():
            continue
        
        image = cv2.imread(img_path)
        if image is None:
            continue
        
        overlay = image.copy()
        
        keypoints_norm = {}
        for kp in data[img_path]:
            keypoints_norm[kp['landmark']] = {
                'x_norm': kp['x_norm'],
                'y_norm': kp['y_norm'],
                'visibility': kp['visibility']
            }
        
        meta_info = meta[img_path]
        keypoints_scaled = denormalize_keypoints(
            keypoints_norm, 
            meta_info['center_x'], 
            meta_info['center_y'], 
            meta_info['unit_length'],
            image.shape, 
            meta_info['bbox']
        )
        
        # рисуем скелет
        skeleton_color = (0, 255, 0)
        for connection in SKELETON_CONNECTIONS:
            point1, point2 = connection
            if point1 in keypoints_scaled and point2 in keypoints_scaled:
                p1 = keypoints_scaled[point1]
                p2 = keypoints_scaled[point2]
                cv2.line(overlay, p1, p2, skeleton_color, 3)
        
        # рисуем ключевые точки
        for landmark, (x, y) in keypoints_scaled.items():
            cv2.circle(overlay, (x, y), 8, skeleton_color, -1)
            cv2.circle(overlay, (x, y), 8, (255, 255, 255), 2)
        
        # рисуем туловище
        if all(pt in keypoints_scaled for pt in TORSO_POINTS):
            pts = np.array([keypoints_scaled[pt] for pt in TORSO_POINTS], np.int32)
            cv2.polylines(overlay, [pts], isClosed=True, color=(255, 255, 0), thickness=2)
        
        image = cv2.addWeighted(overlay, 0.7, image, 0.3, 0)
        
        output_img_path = output_dir / Path(img_path).name
        cv2.imwrite(str(output_img_path), image)
    
    logger.info(f"скелеты для обучения сохранены: {output_dir}")
    return output_dir


class FitnessPipelineManager:
    def __init__(self):
        with open(CONFIG_PATH) as f:
            self.config = yaml.safe_load(f)
        
        self.model = ExerciseRecognitionModel(device='cpu')
        logger.info("FitnessPipelineManager инициализирован")
    
    def step1_extract_frames_from_videos(self, video_dir):
 # нарезка всех видео на кадры
        logger.info("=" * 70)
        logger.info("нарезка ВСЕХ видео на кадры")
        logger.info("=" * 70)
        
        video_dir = Path(video_dir)
        frames_output_base = DATA_DIR / 'visualizations' / 'video'
        frames_output_base.mkdir(parents=True, exist_ok=True)
        
        # ищем все видеофайлы
        all_videos = list(video_dir.glob('**/*.mp4')) + list(video_dir.glob('**/*.mov'))
        
        if not all_videos:
            logger.error(f"видео не найдены в {video_dir}")
            return frames_output_base
        
        logger.info(f"найдено видео: {len(all_videos)}\n")
        
        # обрабатываем каждое видео
        for video_path in tqdm(all_videos, desc="нарезка видео"):
            exercise_type = video_path.parent.name
            frames_output = frames_output_base / f"{exercise_type}_{video_path.stem}"
            frames_output.mkdir(parents=True, exist_ok=True)
            
            try:
                video_to_frames(str(video_path), str(frames_output), video_path.stem)
                logger.info(f"{video_path.name} → {frames_output.name}")
            except Exception as e:
                logger.error(f"ошибка обработки {video_path.name}: {e}", exc_info=True)
                continue
        
        logger.info(f"\n все видео нарезаны: {frames_output_base}\n")
        return frames_output_base
    
    def step2_extract_poses_from_frames(self, frames_base_dir):
       # извлечение поз из всех кадров
        logger.info("=" * 70)
        logger.info("Извлечение поз из всех кадров")
        logger.info("=" * 70)
        
        frames_base_dir = Path(frames_base_dir)
        annotations_dir = DATA_DIR / 'annotations'
        annotations_dir.mkdir(parents=True, exist_ok=True)
        
        extractor = FitnessPoseExtractor(
            yolo_model_path=str(MODELS_DIR / 'yolov8n-pose.pt'),
            config_path=str(CONFIG_PATH)
        )
        
        # ищем папки с кадрами
        frame_dirs = [d for d in frames_base_dir.iterdir() if d.is_dir()]
        
        if not frame_dirs:
            logger.error(f"Папок с кадрами не найдено в {frames_base_dir}")
            return []
        
        logger.info(f"📁 Найдено папок: {len(frame_dirs)}\n")
        
        all_pose_csvs = []
        
        # Обрабатываем каждую папку с кадрами
        for frames_dir in tqdm(frame_dirs, desc="🔍 Извлечение поз"):
            if not frames_dir.is_dir():
                continue
            
            # Определяем тип упражнения
            dir_name = frames_dir.name.lower()
            if 'pushup' in dir_name:
                exercise_type = 'pushup'
            elif 'pullup' in dir_name:
                exercise_type = 'pullup'
            else:
                exercise_type = 'unknown'
            
            output_csv = annotations_dir / f"{exercise_type}_{frames_dir.name}_poses.csv"
            
            try:
                # Извлекаем позы
                extractor.process_video_frames(str(frames_dir), str(output_csv))
                
                if output_csv.exists() and output_csv.stat().st_size > 0:
                    all_pose_csvs.append((exercise_type, output_csv))
                    logger.info(f" {frames_dir.name} → {output_csv.name}")
                else:
                    logger.warning(f" Пустой CSV: {output_csv}")
            except Exception as e:
                logger.error(f" Ошибка обработки {frames_dir.name}: {e}", exc_info=True)
                continue
        
        logger.info(f"\n Всего CSV файлов: {len(all_pose_csvs)}\n")
        return all_pose_csvs
    
    def step25_draw_skeleton_all_videos(self, pose_csvs, frames_dir):
        logger.info("=" * 70)
        logger.info("рисование скелетов для всех видео")
        logger.info("=" * 70)
        
        skeleton_output_base = DATA_DIR / 'visualizations' / 'skeleton_frames'
        skeleton_output_base.mkdir(parents=True, exist_ok=True)
        
        frames_dir = Path(frames_dir)
        
        for exercise_type, csv_path in tqdm(pose_csvs, desc="🎨 Рисую скелеты"):
            # Определяем папку для скелетов
            frames_subdir = csv_path.stem.replace('_poses', '')
            skeleton_output = skeleton_output_base / frames_subdir
            skeleton_output.mkdir(parents=True, exist_ok=True)
            
            try:
                draw_training_skeleton_frames(str(csv_path), str(frames_dir), str(skeleton_output))
                logger.info(f" {csv_path.stem} → {skeleton_output.name}")
            except Exception as e:
                logger.error(f" ошибка рисования {csv_path.stem}: {e}", exc_info=True)
                continue
        
        logger.info(f"\n все скелеты нарисованы: {skeleton_output_base}\n")
        return skeleton_output_base
    
    def step3_prepare_training_data(self, pose_csvs):
        # Шаг 3: Подготовка данных для обучения
        logger.info("=" * 70)
        logger.info("ШАГ 3: Подготовка данных для обучения")
        logger.info("=" * 70)
        
        X_all = []
        y_all = []
        
        for exercise_type, csv_path in tqdm(pose_csvs, desc="📖 Читаю CSV"):
            
            frame_data = defaultdict(list)
            
            try:
                with open(csv_path, 'r') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        frame_id = int(row['frame_id'])
                        x_norm = float(row['x_norm'])
                        y_norm = float(row['y_norm'])
                        frame_data[frame_id].append([x_norm, y_norm])
            except Exception as e:
                logger.error(f" Ошибка чтения {csv_path}: {e}", exc_info=True)
                continue
            
            if not frame_data:
                logger.warning(f" Нет данных в {csv_path}")
                continue
            
            sorted_frames = sorted(frame_data.keys())
            features = []
            
            for frame_id in sorted_frames:
                coords = frame_data[frame_id]
                flat = np.array(coords).flatten()[:68]
                if len(flat) < 68:
                    flat = np.pad(flat, (0, 68 - len(flat)), mode='constant')
                features.append(flat)
            
            features = np.array(features)
            
            X_all.append(features)
            y_all.extend([exercise_type] * len(features))
            
            logger.info(f"   {csv_path.stem}: {len(features)} кадров ({exercise_type})")
        
        if not X_all:
            logger.error(" Нет данных для обучения!")
            return None, None
        
        X = np.vstack(X_all)
        y = np.array(y_all)
        
        logger.info(f"\n Всего примеров: {len(X)}")
        for cls in np.unique(y):
            count = np.sum(y == cls)
            percentage = 100 * count / len(y)
            logger.info(f"   - {cls}: {count} примеров ({percentage:.1f}%)")
        
        return X, y
    
    def step4_train_model(self, X, y, test_size=0.2):
        """Шаг 4: Обучение модели на ВСЕХ данных с параметрами из config"""
        logger.info("\n" + "=" * 70)
        logger.info("🤖 ШАГ 4: Обучение модели BiLSTM")
        logger.info("=" * 70)
        
        # берём параметры из config
        model_config = self.config['model']
        pushup_config = self.config.get('pushup', {})
        pullup_config = self.config.get('pullup', {})
        
        # Выводим информацию об упражнениях
        logger.info("\n Параметры обучения:")
        logger.info(f"   Классы: {model_config['exercise_types']}")
        logger.info(f"   Hidden size: {model_config['hidden_size']}")
        logger.info(f"   Num layers: {model_config['num_layers']}")
        logger.info(f"   Dropout: {model_config['dropout']}")
        
        logger.info("\n PUSHUP параметры:")
        logger.info(f"   Описание: {pushup_config.get('description', 'N/A')}")
        logger.info(f"   Минимальный угол локтей: {pushup_config.get('correctness_thresholds', {}).get('elbow_bend_angle_min', 'N/A')}°")
        logger.info(f"   Максимальный угол туловища: {pushup_config.get('correctness_thresholds', {}).get('torso_angle_max', 'N/A')}°")
        logger.info(f"   Min вертикального движения: {pushup_config.get('heuristic_thresholds', {}).get('shoulder_vertical_delta_min', 'N/A')}")
        logger.info(f"   Min кадров за повторение: {pushup_config.get('heuristic_thresholds', {}).get('min_frames_required', 'N/A')}")
        
        logger.info("\n PULLUP параметры:")
        logger.info(f"   Описание: {pullup_config.get('description', 'N/A')}")
        logger.info(f"   Минимальный угол локтей: {pullup_config.get('correctness_thresholds', {}).get('elbow_bend_angle_min', 'N/A')}°")
        logger.info(f"   Максимальный угол туловища: {pullup_config.get('correctness_thresholds', {}).get('torso_angle_max', 'N/A')}°")
        logger.info(f"   Поднятие плеч (мин): {pullup_config.get('correctness_thresholds', {}).get('shoulder_elevation_min', 'N/A')}")
        logger.info(f"   Min вертикального движения: {pullup_config.get('heuristic_thresholds', {}).get('shoulder_vertical_delta_min', 'N/A')}")
        logger.info(f"   Min кадров за повторение: {pullup_config.get('heuristic_thresholds', {}).get('min_frames_required', 'N/A')}")
        
        # Разделяем данные
        X_train, X_val, y_train, y_val = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        logger.info(f"\n Разделение данных:")
        logger.info(f"   Train: {len(X_train)} примеров")
        logger.info(f"   Val: {len(X_val)} примеров")
        
        # Выводим распределение классов
        logger.info(f"\n Распределение классов в TRAIN:")
        unique, counts = np.unique(y_train, return_counts=True)
        for exercise, count in zip(unique, counts):
            percentage = 100 * count / len(y_train)
            logger.info(f"   - {exercise}: {count} примеров ({percentage:.1f}%)")
        
        logger.info(f"\n Распределение классов в VAL:")
        unique, counts = np.unique(y_val, return_counts=True)
        for exercise, count in zip(unique, counts):
            percentage = 100 * count / len(y_val)
            logger.info(f"   - {exercise}: {count} примеров ({percentage:.1f}%)")
        
        # обучаем модель с параметрами из config
        logger.info(f"\n Начинаю обучение...")
        logger.info(f"   Эпох: 100")
        logger.info(f"   Batch size: 32")
        logger.info(f"   Learning rate: 0.001")
        logger.info(f"   Hidden size: {model_config['hidden_size']}")
        logger.info(f"   Dropout: {model_config['dropout']}\n")
        
        self.model.train_on_data(
            X_train, y_train,
            X_val, y_val,
            epochs=100,
            batch_size=32,
            lr=0.001
        )
        
        model_path = MODELS_DIR / 'exercise_classifier.pth'
        scaler_path = MODELS_DIR / 'scaler.joblib'
        
        self.model.save_model(str(model_path), str(scaler_path))
        
        logger.info("\n" + "=" * 70)
        logger.info("обучение выполнено")
        logger.info("=" * 70)
        logger.info(f"Модель: {model_path}")
        logger.info(f"Scaler: {scaler_path}")
        logger.info(f"Log файл: {LOG_FILE}")
        logger.info("=" * 70 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Fitness Pipeline Manager - Обучение на всех видео",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
    python src/fitness_pipeline_manager.py --step all
    python src/fitness_pipeline_manager.py --step 1
        """
    )
    
    parser.add_argument('--step', type=str, choices=['1', '2', '2.5', '3', '4', 'all'],
                        default='all',
                        help="Какой шаг выполнить")
    
    parser.add_argument('--video_dir', 
                        default=str(PROJECT_ROOT / 'data' / 'dataset' / 'video'),
                        help="Папка с видео")
    
    parser.add_argument('--frames_dir',
                        default=str(DATA_DIR / 'visualizations' / 'video'),
                        help="Папка с кадрами")
    
    args = parser.parse_args()
    
    manager = FitnessPipelineManager()
    
    # Шаг 1: Нарезка всех видео
    if args.step in ['1', 'all']:
        frames_dir = manager.step1_extract_frames_from_videos(args.video_dir)
    else:
        frames_dir = Path(args.frames_dir)
    
    # Шаг 2: Извлечение поз из всех кадров
    if args.step in ['2', '2.5', '3', '4', 'all']:
        pose_csvs = manager.step2_extract_poses_from_frames(frames_dir)
    else:
        pose_csvs = None
    
    # Шаг 2.5: Рисование скелетов для всех видео
    if args.step in ['2.5', '3', '4', 'all']:
        if pose_csvs:
            manager.step25_draw_skeleton_all_videos(pose_csvs, frames_dir)
    
    # Шаг 3: Подготовка данных
    if args.step in ['3', '4', 'all']:
        if not pose_csvs:
            pose_csvs = manager.step2_extract_poses_from_frames(frames_dir)
        X, y = manager.step3_prepare_training_data(pose_csvs)
    else:
        X, y = None, None
    
    # Шаг 4: Обучение на всех видео
    if args.step in ['4', 'all']:
        if X is None:
            if not pose_csvs:
                pose_csvs = manager.step2_extract_poses_from_frames(frames_dir)
            X, y = manager.step3_prepare_training_data(pose_csvs)
        manager.step4_train_model(X, y)
    
    logger.info("\nPIPELINE ЗАВЕРШЕН!")
    logger.info(f"Log файл: {LOG_FILE}\n")


if __name__ == "__main__":
    main()