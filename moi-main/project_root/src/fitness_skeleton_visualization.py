import os
import csv
import cv2
import numpy as np
from collections import defaultdict
from tqdm import tqdm
import yaml
from exercise_recognition_model import infer_exercise

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

def draw_skeleton(image, keypoints, bbox, pred_info, alpha=0.6):
    overlay = image.copy()
    for start, end in SKELETON_CONNECTIONS:
        if start in keypoints and end in keypoints:
            cv2.line(overlay, keypoints[start], keypoints[end], (0, 255, 255), 1)
    for name, (x, y) in keypoints.items():
        cv2.circle(overlay, (x, y), 3, (0, 0, 255), -1)
    if all(pt in keypoints for pt in TORSO_POINTS):
        pts = np.array([keypoints[pt] for pt in TORSO_POINTS], np.int32)
        cv2.polylines(overlay, [pts], isClosed=True, color=(255, 255, 0), thickness=1)
    
    x1, y1, x2, y2 = bbox
    color = (0, 255, 0) if pred_info['correctness'] == 'correct' else (0, 0, 255)
    cv2.rectangle(overlay, (x1, y1), (x2, y2), color, 2)
    text = f"{pred_info['exercise_type']}: {pred_info['correctness']}"
    cv2.putText(overlay, text, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
    
    cv2.addWeighted(overlay, alpha, image, 1 - alpha, 0, image)

def visualize(
    csv_path: str,
    output_dir: str = None,
    min_visibility: float = 0.5,
    clean_canvas: bool = False,
    live: bool = False,
    sample_size: int = None
):
    if live:
        import mediapipe as mp
        cap = cv2.VideoCapture(0)
        mp_pose = mp.solutions.pose
        pose = mp_pose.Pose(
            static_image_mode=False,
            model_complexity=2,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)
            if results.pose_landmarks:
                mp.solutions.drawing_utils.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
            cv2.imshow('Визуализация позы в реальном времени', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        cap.release()
        cv2.destroyAllWindows()
        return

    data = defaultdict(list)
    meta = {}
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
                if img_path not in meta:
                    meta[img_path] = {
                        'center_x': float(row['center_x']),
                        'center_y': float(row['center_y']),
                        'unit_length': float(row['unit_length']),
                        'bbox': eval(row['bbox'])
                    }

    img_paths = sorted(list(data.keys()))
    if sample_size is not None and sample_size > 0:
        img_paths = img_paths[:sample_size]

    # Получаем путь к config.yaml относительно project_root
    from pathlib import Path
    project_root = Path(__file__).parent.parent
    config_path = str(project_root / 'config/config.yaml')
    predictions = infer_exercise(csv_path, config_path)

    pred_dict = {p['frame_id']: p for p in predictions}

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
        keypoints_norm = {kp['landmark']: {'x_norm': kp['x_norm'], 'y_norm': kp['y_norm']} 
                         for kp in data[img_path]}
        meta_info = meta[img_path]
        frame_id = os.path.basename(img_path).split('_')[-1].split('.')[0]
        pred_info = pred_dict.get(int(frame_id), {'exercise_type': 'unknown', 'correctness': 'unknown'})
        keypoints_scaled = denormalize_keypoints(
            keypoints_norm, meta_info['center_x'], meta_info['center_y'], meta_info['unit_length'],
            image.shape, meta_info['bbox']
        )
        draw_skeleton(image, keypoints_scaled, meta_info['bbox'], pred_info)
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