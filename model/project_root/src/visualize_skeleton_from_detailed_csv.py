import os
import csv
import cv2
import numpy as np
from collections import defaultdict
from tqdm import tqdm

# Определяем связи между суставами для анатомически корректного скелета
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
    """
    Де-нормализация ключевых точек с учетом bounding box и анатомических пропорций.
    """
    height, width = image_shape[:2]
    keypoints_scaled = {}
    
    # Извлекаем координаты bounding box
    x1, y1, x2, y2 = bbox
    bbox_width = x2 - x1
    bbox_height = y2 - y1
    
    for name, kp in keypoints_norm.items():
        try:
            # Масштабируем координаты относительно bounding box
            x = x1 + (center_x + kp['x_norm'] * unit_length) * bbox_width
            y = y1 + (center_y + kp['y_norm'] * unit_length) * bbox_height
            
            # Ограничиваем координаты в пределах изображения
            x = max(x1, min(x, x2))
            y = max(y1, min(y, y2))
            
            keypoints_scaled[name] = (int(x), int(y))
        except (KeyError, ValueError) as e:
            print(f"Ошибка обработки ключевой точки {name}: {e}")
            continue
    return keypoints_scaled

def draw_skeleton(image, keypoints, bbox, draw_torso=True, alpha=0.6):
    """
    Отрисовка скелета с акцентом на анатомическую точность.
    """
    overlay = image.copy()
    
    # Рисуем линии скелета (тонкие, чтобы выглядели как "сканирование")
    for start, end in SKELETON_CONNECTIONS:
        if start in keypoints and end in keypoints:
            cv2.line(overlay, keypoints[start], keypoints[end], (0, 255, 255), 1)  # Желтые линии, толщина 1

    # Рисуем ключевые точки (суставы) четко и ярко
    for name, (x, y) in keypoints.items():
        cv2.circle(overlay, (x, y), 3, (0, 0, 255), -1)  # Красные точки, радиус 3

    # Рисуем торс как тонкий контур
    if draw_torso and all(pt in keypoints for pt in TORSO_POINTS):
        pts = np.array([keypoints[pt] for pt in TORSO_POINTS], np.int32)
        cv2.polylines(overlay, [pts], isClosed=True, color=(255, 255, 0), thickness=1)

    # Накладываем оверлей с полупрозрачностью
    cv2.addWeighted(overlay, alpha, image, 1 - alpha, 0, image)

def visualize(
    csv_path=None, 
    output_dir=None, 
    min_visibility=0.5, 
    clean_canvas=False, 
    live=False, 
    sample_size=None
):
    if live:
        cap = cv2.VideoCapture(0)
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            cv2.imshow('Визуализация позы в реальном времени', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        cap.release()
        cv2.destroyAllWindows()
        return

    data = defaultdict(list)
    meta = {}

    # Читаем CSV файл с аннотациями
    try:
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                img_path = row['image_path']
                if float(row['visibility']) >= min_visibility:
                    data[img_path].append({
                        'landmark': row['landmark'],
                        'x_norm': float(row['x_norm']),
                        'y_norm': float(row['y_norm'])
                    })
                    # Извлекаем метаданные, включая bounding box
                    meta[img_path] = {
                        'center_x': float(row['center_x']),
                        'center_y': float(row['center_y']),
                        'unit_length': float(row['unit_length']),
                        'bbox': eval(row['bbox'])  # Предполагаем, что bbox сохранен как список
                    }
    except FileNotFoundError:
        print(f"CSV файл не найден: {csv_path}")
        return
    except Exception as e:
        print(f"Ошибка чтения CSV: {e}")
        return

    img_paths = sorted(list(data.keys()))
    if sample_size is not None and sample_size > 0:
        img_paths = img_paths[:sample_size]

    for img_path in tqdm(img_paths, desc="Визуализация скелетов"):
        if not os.path.exists(img_path):
            print(f"Изображение {img_path} не найдено, пропускаем.")
            continue

        image = cv2.imread(img_path)
        if image is None:
            print(f"Не удалось прочитать изображение {img_path}, пропускаем.")
            continue

        if clean_canvas:
            image = np.ones_like(image) * 255

        # Формируем словарь ключевых точек
        keypoints_norm = {kp['landmark']: {'x_norm': kp['x_norm'], 'y_norm': kp['y_norm']} 
                         for kp in data[img_path]}
        meta_info = meta[img_path]
        
        # Де-нормализация с учетом bounding box
        keypoints_scaled = denormalize_keypoints(
            keypoints_norm, 
            meta_info['center_x'], 
            meta_info['center_y'], 
            meta_info['unit_length'], 
            image.shape,
            meta_info['bbox']
        )

        # Отрисовка скелета
        draw_skeleton(image, keypoints_scaled, meta_info['bbox'])

        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
            output_img_path = os.path.join(output_dir, os.path.basename(img_path))
            cv2.imwrite(output_img_path, image)
        else:
            cv2.imshow('Визуализация скелета', image)
            cv2.waitKey(0)
            cv2.destroyAllWindows()

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv_path', default=None)
    parser.add_argument('--output_dir', default=None)
    parser.add_argument('--clean_canvas', action='store_true')
    parser.add_argument('--live', action='store_true')
    parser.add_argument('--sample_size', type=int, default=None)
    args = parser.parse_args()
    
    visualize(
        csv_path=args.csv_path,
        output_dir=args.output_dir,
        clean_canvas=args.clean_canvas,
        live=args.live,
        sample_size=args.sample_size
    )