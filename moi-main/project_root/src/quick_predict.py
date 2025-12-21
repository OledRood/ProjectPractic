import logging
import numpy as np
import csv
import cv2
from pathlib import Path
from collections import defaultdict
from exercise_recognition_model import ExerciseRecognitionModel
from fitness_pose_extraction import FitnessPoseExtractor
from video_to_frames import video_to_frames
from merge_frames_to_video import merge_frames_to_video
from tqdm import tqdm
import yaml
import os
import argparse

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_PATH = PROJECT_ROOT / 'config' / 'config.yaml'
MODELS_DIR = PROJECT_ROOT / 'models'
TEMP_FRAMES_DIR = PROJECT_ROOT / 'data' / 'temp_frames'
TEMP_ANNOTATIONS_DIR = PROJECT_ROOT / 'data' / 'temp_skeletons'

# рисование скелета
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


class SkeletonValidator:
    # валидация скелета по параметрам из config.yaml
    
    def __init__(self):
        with open(CONFIG_PATH) as f:
            self.config = yaml.safe_load(f)
        
        self.pushup_config = self.config.get('pushup', {})
        self.pullup_config = self.config.get('pullup', {})
    
    def calculate_angle(self, point1, point2, point3):
        #Вычисляет угол между тремя точками (в градусах)
        try:
            a = np.array(point1, dtype=np.float32)
            b = np.array(point2, dtype=np.float32)
            c = np.array(point3, dtype=np.float32)
            
            ba = a - b
            bc = c - b
            
            norm_ba = np.linalg.norm(ba)
            norm_bc = np.linalg.norm(bc)
            
            if norm_ba < 1e-6 or norm_bc < 1e-6:
                return None
            
            cosine_angle = np.dot(ba, bc) / (norm_ba * norm_bc)
            cosine_angle = np.clip(cosine_angle, -1.0, 1.0)
            angle = np.arccos(cosine_angle)
            return np.degrees(angle)
        except:
            return None
    
    def calculate_distance(self, point1, point2):
        # Расстояние между двумя точками
        try:
            return np.linalg.norm(np.array(point1, dtype=np.float32) - np.array(point2, dtype=np.float32))
        except:
            return None
    
    def denormalize_keypoints(self, keypoints_norm, center_x, center_y, unit_length, bbox, image_shape):
        # Денормализует координаты с учетом bbox
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
    
    def validate_pushup(self, keypoints, image_shape):
        
        config = self.pushup_config.get('correctness_thresholds', {})
        
        issues = []
        metrics = {}
        problems = []
        
        available = set(keypoints.keys())
        
        # проверка на локоть
        if 'RIGHT_SHOULDER' in available and 'RIGHT_ELBOW' in available and 'RIGHT_WRIST' in available:
            elbow_angle = self.calculate_angle(
                keypoints['RIGHT_SHOULDER'],
                keypoints['RIGHT_ELBOW'],
                keypoints['RIGHT_WRIST']
            )
            min_angle = config.get('elbow_bend_angle_min', 80)
            
            if elbow_angle and elbow_angle >= min_angle:
                issues.append(f"Локоть согнут: {elbow_angle:.0f}° (норма >= {min_angle}°)")
            elif elbow_angle:
                issues.append(f"Локоть недостаточно согнут: {elbow_angle:.0f}° < {min_angle}°")
                problems.append(f"Увеличьте сгиб локтя до {min_angle}°")
            
            metrics['elbow_angle'] = elbow_angle
        
        # проверка на спину
        if ('LEFT_SHOULDER' in available or 'RIGHT_SHOULDER' in available) and 'LEFT_HIP' in available and 'RIGHT_HIP' in available:
            shoulder_point = keypoints['LEFT_SHOULDER'] if 'LEFT_SHOULDER' in available else keypoints['RIGHT_SHOULDER']
            torso_angle = self.calculate_angle(
                shoulder_point,
                keypoints['LEFT_HIP'],
                keypoints['RIGHT_HIP']
            )
            
            # Для отжимания спина
            ideal_angle = 90
            angle_diff = abs(torso_angle - ideal_angle) if torso_angle else None
            
            if angle_diff and angle_diff < 30:
                issues.append(f"Спина прямая: {torso_angle:.0f}°")
            elif angle_diff:
                issues.append(f"Спина наклонена: {torso_angle:.0f}° (должна быть ~90°)")
                problems.append(f"Выпрямите спину - держите её параллельно полу")
            
            metrics['torso_angle'] = torso_angle
        
        # проверка на ноги
        if 'RIGHT_HIP' in available and 'RIGHT_KNEE' in available and 'RIGHT_ANKLE' in available:
            knee_angle = self.calculate_angle(
                keypoints['RIGHT_HIP'],
                keypoints['RIGHT_KNEE'],
                keypoints['RIGHT_ANKLE']
            )
            
            if knee_angle and knee_angle > 160:
                issues.append(f"Ноги прямые: {knee_angle:.0f}°")
            elif knee_angle:
                issues.append(f"Ноги согнуты: {knee_angle:.0f}°")
                problems.append(f"Выпрямите ноги")
            
            metrics['knee_angle'] = knee_angle
        
        if not issues:
            issues.append("Недостаточно данных для анализа")
        
        return {
            'issues': issues,
            'metrics': metrics,
            'problems': problems
        }
    
    def validate_pullup(self, keypoints, image_shape):
        
        config = self.pullup_config.get('correctness_thresholds', {})
        
        issues = []
        metrics = {}
        problems = []
        
        available = set(keypoints.keys())
        
        # проверка на локоть
        if 'RIGHT_SHOULDER' in available and 'RIGHT_ELBOW' in available and 'RIGHT_WRIST' in available:
            elbow_angle = self.calculate_angle(
                keypoints['RIGHT_SHOULDER'],
                keypoints['RIGHT_ELBOW'],
                keypoints['RIGHT_WRIST']
            )
            min_angle = config.get('elbow_bend_angle_min', 90)
            
            if elbow_angle and elbow_angle >= min_angle:
                issues.append(f"Локоть согнут: {elbow_angle:.0f}° (норма >= {min_angle}°)")
            elif elbow_angle:
                issues.append(f"Локоть не согнут достаточно: {elbow_angle:.0f}° < {min_angle}°")
                problems.append(f"Подтягивайтесь выше")
            
            metrics['elbow_angle'] = elbow_angle
        
        # проверка на локоть
        if 'RIGHT_SHOULDER' in available and 'RIGHT_ELBOW' in available:
            shoulder_y = keypoints['RIGHT_SHOULDER'][1]
            elbow_y = keypoints['RIGHT_ELBOW'][1]
            
            if shoulder_y < elbow_y:
                issues.append(f"Плечи выше локтей")
            else:
                issues.append(f"Плечи ниже локтей")
                problems.append(f"Подтягивайтесь выше")
            
            metrics['shoulders_high'] = shoulder_y < elbow_y
        
        # проверка на корпус
        if 'RIGHT_SHOULDER' in available and 'LEFT_HIP' in available and 'RIGHT_HIP' in available:
            torso_angle = self.calculate_angle(
                keypoints['RIGHT_SHOULDER'],
                keypoints['LEFT_HIP'],
                keypoints['RIGHT_HIP']
            )
            
            ideal_angle = 90
            angle_diff = abs(torso_angle - ideal_angle) if torso_angle else None
            
            if angle_diff and angle_diff < 30:
                issues.append(f"Корпус вертикален: {torso_angle:.0f}°")
            elif angle_diff:
                issues.append(f"Корпус наклонен: {torso_angle:.0f}°")
                problems.append(f"Не раскачивайтесь - держите корпус вертикально")
            
            metrics['torso_angle'] = torso_angle
        
        # проверка на ноги
        if 'RIGHT_HIP' in available and 'RIGHT_KNEE' in available and 'RIGHT_ANKLE' in available:
            knee_angle = self.calculate_angle(
                keypoints['RIGHT_HIP'],
                keypoints['RIGHT_KNEE'],
                keypoints['RIGHT_ANKLE']
            )
            
            if knee_angle and knee_angle > 160:
                issues.append(f"Ноги прямые: {knee_angle:.0f}°")
            elif knee_angle:
                issues.append(f"Ноги согнуты: {knee_angle:.0f}°")
                problems.append(f"Ноги должны быть прямыми")
            
            metrics['knee_angle'] = knee_angle
        
        if not issues:
            issues.append("⚠️ Недостаточно данных для анализа")
        
        return {
            'issues': issues,
            'metrics': metrics,
            'problems': problems
        }


def denormalize_keypoints(keypoints_norm, center_x, center_y, unit_length, image_shape, bbox):
    # Денормализует координаты с учетом bbox
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


def draw_skeleton_on_frames(csv_path, frames_dir, output_dir):
    logger.info("\nРисую скелеты на кадрах...")
    
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Читаем CSV с позами
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
    
    for img_path in tqdm(img_paths, desc="Рисую скелеты"):
        if not Path(img_path).exists():
            continue
        
        image = cv2.imread(img_path)
        if image is None:
            continue
        
        overlay = image.copy()
        
        # Извлекаем координаты ориентиров
        keypoints_norm = {}
        for kp in data[img_path]:
            keypoints_norm[kp['landmark']] = {
                'x_norm': kp['x_norm'],
                'y_norm': kp['y_norm'],
                'visibility': kp['visibility']
            }
        
        meta_info = meta[img_path]
        
        # Денормализуем координаты
        keypoints_scaled = denormalize_keypoints(
            keypoints_norm, 
            meta_info['center_x'], 
            meta_info['center_y'], 
            meta_info['unit_length'],
            image.shape, 
            meta_info['bbox']
        )
        
        # линии скелета
        skeleton_color = (0, 255, 0)
        for connection in SKELETON_CONNECTIONS:
            point1, point2 = connection
            if point1 in keypoints_scaled and point2 in keypoints_scaled:
                p1 = keypoints_scaled[point1]
                p2 = keypoints_scaled[point2]
                cv2.line(overlay, p1, p2, skeleton_color, 3)
        
        # суставы
        for landmark, (x, y) in keypoints_scaled.items():
            cv2.circle(overlay, (x, y), 8, skeleton_color, -1)
            cv2.circle(overlay, (x, y), 8, (255, 255, 255), 2)
        
        # туловище
        if all(pt in keypoints_scaled for pt in TORSO_POINTS):
            pts = np.array([keypoints_scaled[pt] for pt in TORSO_POINTS], np.int32)
            cv2.polylines(overlay, [pts], isClosed=True, color=(255, 255, 0), thickness=2)
        
        # рисуем bbox
        x1, y1, x2, y2 = meta_info['bbox']
        cv2.rectangle(overlay, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)
        
        # Смешиваем overlay с оригиналом
        image = cv2.addWeighted(overlay, 0.7, image, 0.3, 0)
        
        # Сохраняем кадр со скелетом
        output_img_path = output_dir / Path(img_path).name
        cv2.imwrite(str(output_img_path), image)
    
    logger.info(f"✅ Скелеты нарисованы: {output_dir}")
    return output_dir


def predict_video(video_path, confidence_threshold=0.7):
# основная функция анализа видео с упражнениями
    
    video_path = Path(video_path)
    
    logger.info("=" * 80)
    logger.info(f"анализируем видео: {video_path.name}")
    logger.info("=" * 80)
    
    # Нарезка видео на кадры
    temp_frames_dir = TEMP_FRAMES_DIR / video_path.stem
    temp_frames_dir.mkdir(parents=True, exist_ok=True)
    
    logger.info("\nШАГ 1: Нарезка видео на кадры...")
    video_to_frames(str(video_path), str(temp_frames_dir), video_path.stem)
    
    # Шаг 2: Извлечение поз
    logger.info("ШАГ 2: Извлечение поз...")
    temp_csv = TEMP_ANNOTATIONS_DIR / f"{video_path.stem}_poses.csv"
    temp_csv.parent.mkdir(parents=True, exist_ok=True)
    
    extractor = FitnessPoseExtractor(
        yolo_model_path=str(MODELS_DIR / 'yolov8n-pose.pt'),
        config_path=str(CONFIG_PATH)
    )
    extractor.process_video_frames(str(temp_frames_dir), str(temp_csv))
    
    if not os.path.exists(temp_csv):
        logger.warning(f"CSV файл не найден: {temp_csv}")
        logger.info("Возможно, в видео не обнаружены люди для анализа поз")
        return
    
    logger.info(f"Позы сохранены: {temp_csv}")
    
    # рисуем скелеты на кадрах
    skeleton_frames_dir = TEMP_FRAMES_DIR / video_path.stem / 'skeleton_frames'
    try:
        draw_skeleton_on_frames(str(temp_csv), str(temp_frames_dir), str(skeleton_frames_dir))
    except Exception as e:
        logger.error(f"Ошибка при рисовании скелетов: {e}")
    
    # Шаг 3: Загрузка CSV
    logger.info("ШАГ 3: Подготовка данных...")
    
    frame_data = defaultdict(list)
    frame_metadata = {}

    with open(temp_csv, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            frame_id = int(row['frame_id'])
            x_norm = float(row['x_norm'])
            y_norm = float(row['y_norm'])
            landmark = row['landmark']
            
            frame_data[frame_id].append([x_norm, y_norm])
            
            if frame_id not in frame_metadata:
                frame_metadata[frame_id] = {
                    'image_path': row['image_path'],
                    'center_x': float(row['center_x']),
                    'center_y': float(row['center_y']),
                    'unit_length': float(row['unit_length']),
                    'bbox': eval(row['bbox'])
                }
    
    sorted_frames = sorted(frame_data.keys())
    X_sequences = []
    seq_length = 30
    stride = 1
    
    # Адаптивный seq_length если видео короткое
    if len(sorted_frames) < 60:
        seq_length = max(10, len(sorted_frames) // 3)
        logger.warning(f"Видео короткое! Использую адаптивный seq_length={seq_length}")
    
    for i in range(0, len(sorted_frames) - seq_length + 1, stride):
        sequence = []
        for j in range(seq_length):
            frame_id = sorted_frames[i + j]
            coords = frame_data[frame_id]
            flat = np.array(coords).flatten()[:68]
            if len(flat) < 68:
                flat = np.pad(flat, (0, 68 - len(flat)), mode='constant')
            sequence.append(flat)
        X_sequences.append(sequence)
    
    X_sequences = np.array(X_sequences)
    logger.info(f"Создано {len(X_sequences)} окон анализа\n")
    
    # Шаг 4: Предсказание
    logger.info("ШАГ 4: Анализ упражнения...")
    
    model = ExerciseRecognitionModel(device='cpu')
    model.load_model(
        str(MODELS_DIR / 'exercise_classifier.pth'),
        str(MODELS_DIR / 'scaler.joblib')
    )
    
    classes = model.classes_
    
    predictions = []
    probabilities = []
    
    import torch
    with torch.no_grad():
        for seq in X_sequences:
            seq_normalized = model.scaler.transform(seq.reshape(-1, seq.shape[-1])).reshape(seq.shape)
            X_tensor = torch.FloatTensor(seq_normalized).unsqueeze(0)
            logits = model.model(X_tensor)
            probs = torch.softmax(logits, dim=1).cpu().numpy()[0]
            pred_idx = np.argmax(probs)
            pred = classes[pred_idx]
            
            predictions.append(pred)
            probabilities.append(probs)
    
    predictions = np.array(predictions)
    probabilities = np.array(probabilities)
    
    # определяем упражнение
    exercise_counts = defaultdict(int)
    exercise_confidences = defaultdict(list)
    
    for pred, prob in zip(predictions, probabilities):
        exercise_counts[pred] += 1
        max_prob = np.max(prob)
        exercise_confidences[pred].append(max_prob)
    
    # если нет предсказаний вообще
    if not exercise_counts:
        logger.error("Не удалось распознать упражнение")
        return {
            'exercise': 'unknown',
            'confidence': 0.0,
            'validation': {'issues': ['Упражнение не распознано'], 'metrics': {}, 'problems': []},
            'all_results': {}
        }
    
    final_exercise = max(exercise_counts.keys(), key=lambda x: exercise_counts[x])
    exercise_count = exercise_counts[final_exercise]
    avg_confidence = np.mean(exercise_confidences[final_exercise])
    
    # если уверенность слишком низкая
    if avg_confidence < 0.3:
        logger.warning(f"Уверенность критически низкая: {avg_confidence:.1%}")
        final_exercise = 'unknown'
    
    # валидируем для конкретного упражнения
    validator = SkeletonValidator()
    
    mid_frame_idx = len(sorted_frames) // 2
    mid_frame_id = sorted_frames[mid_frame_idx]
    
    keypoints_norm = {}
    with open(temp_csv, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if int(row['frame_id']) == mid_frame_id:
                landmark = row['landmark']
                keypoints_norm[landmark] = {
                    'x_norm': float(row['x_norm']),
                    'y_norm': float(row['y_norm'])
                }
    
    if mid_frame_id in frame_metadata:
        meta = frame_metadata[mid_frame_id]
        image_path = meta['image_path']
        
        try:
            img = cv2.imread(image_path)
            image_shape = img.shape if img is not None else (480, 640, 3)
        except:
            image_shape = (480, 640, 3)
        
        keypoints_scaled = validator.denormalize_keypoints(
            keypoints_norm,
            meta['center_x'],
            meta['center_y'],
            meta['unit_length'],
            meta['bbox'],
            image_shape
        )
        
        # валидируем то упражнение, которое определили
        if final_exercise == 'pushup':
            validation = validator.validate_pushup(keypoints_scaled, image_shape)
        else:  # pullup
            validation = validator.validate_pullup(keypoints_scaled, image_shape)
    else:
        validation = {'issues': [], 'metrics': {}, 'problems': ['⚠️ Не удалось загрузить метаданные']}
    
    # вывод упражнения потом метрика
    logger.info("\n" + "=" * 80)
    logger.info("ИТОГОВЫЙ РЕЗУЛЬТАТ")
    logger.info("=" * 80)
    
    logger.info(f"\nУПРАЖНЕНИЕ: {final_exercise.upper()}")
    logger.info(f"УВЕРЕННОСТЬ: {avg_confidence:.1%}")
    logger.info(f"КАДРОВ: {exercise_count}/{len(predictions)} ({exercise_count/len(predictions)*100:.1f}%)")
    
    if avg_confidence < confidence_threshold:
        logger.warning(f"УВЕРЕННОСТЬ НИЗКАЯ! ({avg_confidence:.1%} < {confidence_threshold:.1%})")
    
    # анализ техники упр
    logger.info(f"\nАНАЛИЗ ТЕХНИКИ ({final_exercise.upper()}):")
    logger.info("-" * 80)
    
    for issue in validation['issues']:
        logger.info(f"   {issue}")
    
    if validation['problems']:
        logger.warning(f"\nНАЙДЕНЫ ПРОБЛЕМЫ ТЕХНИКИ:")
        for problem in validation['problems']:
            logger.warning(f"   • {problem}")
    else:
        logger.info(f"\nТЕХНИКА ВЫПОЛНЕНИЯ ИДЕАЛЬНА!")
    
    # метрика для выбр упр
    logger.info(f"\nМЕТРИКИ:")
    if validation['metrics']:
        for metric, value in validation['metrics'].items():
            if metric == 'shoulders_high':
                continue
            
            if isinstance(value, bool):
                status = "да" if value else "нет"
                logger.info(f"   {status} {metric}: {value}")
            elif isinstance(value, (int, float)):
                logger.info(f"   {metric}: {value:.2f}°")
    else:
        logger.warning("   Метрики не рассчитаны")
    
    # собираем видосик
    if skeleton_frames_dir.exists():
        output_video_dir = PROJECT_ROOT / 'data' / 'output_videos'
        output_video_dir.mkdir(parents=True, exist_ok=True)
        output_video_path = output_video_dir / f"{video_path.stem}_skeleton.mp4"
        merge_frames_to_video(skeleton_frames_dir, output_video_path, fps=30)
        logger.info(f"\nВидео со скелетами: {output_video_path}")
    
    logger.info("=" * 80 + "\n")
    
    return {
        'exercise': final_exercise,
        'confidence': round(avg_confidence, 2),
        'validation': validation,
        'all_results': exercise_counts
    }


def main():
    parser = argparse.ArgumentParser(
        description="Анализ упражнения с детальной валидацией техники"
    )
    
    parser.add_argument('--video', required=True, help='Видео для анализа')
    parser.add_argument('--threshold', type=float, default=0.7, help='Threshold уверенности')
    
    args = parser.parse_args()
    predict_video(args.video, confidence_threshold=args.threshold)


if __name__ == "__main__":
    main()