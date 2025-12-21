import os
import csv
import cv2
import numpy as np
from pathlib import Path
from dataclasses import dataclass
from ultralytics import YOLO
import mediapipe as mp
import yaml
from tqdm import tqdm

@dataclass
class PoseResult:
    image_path: str
    bbox: list
    keypoints: dict
    center_x: float
    center_y: float
    unit_length: float
    frame_id: str

class FitnessPoseExtractor:
    def __init__(self, yolo_model_path='models/yolov8n-pose.pt', config_path='config/config.yaml'):
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        self.yolo = YOLO(yolo_model_path)
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=config['mediapipe']['model_complexity'],
            min_detection_confidence=config['mediapipe']['min_detection_confidence'],
            min_tracking_confidence=config['mediapipe']['min_tracking_confidence']
        )
        self.required_landmarks = [
            'LEFT_SHOULDER', 'RIGHT_SHOULDER',
            'LEFT_HIP', 'RIGHT_HIP'
        ]
        self.optional_landmarks = [
            'LEFT_ELBOW', 'RIGHT_ELBOW',
            'LEFT_WRIST', 'RIGHT_WRIST',
            'LEFT_KNEE', 'RIGHT_KNEE',
            'LEFT_ANKLE', 'RIGHT_ANKLE',
            'LEFT_EYE', 'RIGHT_EYE'
        ]
        self.landmark_names = self.required_landmarks + self.optional_landmarks

    def _calculate_body_center(self, landmarks):
        key_points = [
            self.mp_pose.PoseLandmark.LEFT_SHOULDER,
            self.mp_pose.PoseLandmark.RIGHT_SHOULDER,
            self.mp_pose.PoseLandmark.LEFT_HIP,
            self.mp_pose.PoseLandmark.RIGHT_HIP
        ]
        valid_points = [landmarks[kp.value] for kp in key_points if landmarks[kp.value].visibility > 0.5]
        if not valid_points:
            return None, None
        x_coords = [pt.x for pt in valid_points]
        y_coords = [pt.y for pt in valid_points]
        return np.mean(x_coords), np.mean(y_coords)

    def _calculate_unit_length(self, landmarks):
        # Вычисляет длину единицы (диагональ между плечом и бедром)
        ls = landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER.value]
        rb = landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP.value]
        rs = landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER.value]
        lb = landmarks[self.mp_pose.PoseLandmark.LEFT_HIP.value]

        if ls.visibility < 0.5 or rb.visibility < 0.5 or rs.visibility < 0.5 or lb.visibility < 0.5:
            return 0.1

        diag1 = np.hypot(ls.x - rb.x, ls.y - rb.y)
        diag2 = np.hypot(rs.x - lb.x, rs.y - lb.y)
        unit_length = (diag1 + diag2) / 2
        
        unit_length = max(unit_length, 0.01)
        
        return unit_length

    def _normalize_keypoints(self, landmarks, center_x, center_y, unit_length):
        if center_x is None or center_y is None:
            return None

        normalized = {}
        for name in self.landmark_names:
            idx = getattr(self.mp_pose.PoseLandmark, name).value
            landmark = landmarks[idx]
            if landmark.visibility < 0.5:
                continue

            normalized[name] = {
                'x_norm': (landmark.x - center_x) / unit_length,
                'y_norm': (landmark.y - center_y) / unit_length,
                'visibility': landmark.visibility
            }

        for name in self.required_landmarks:
            if name not in normalized:
                return None

        return normalized

    def _extract_pose_data(self, detection, image, image_path):
        pose_data = []
        boxes = detection.boxes.xyxy.cpu().numpy()
        confidences = detection.boxes.conf.cpu().numpy()

        if len(boxes) > 1:
            # Выбираем человека с наибольшим bbox и высоким confidence
            areas = [(box[2] - box[0]) * (box[3] - box[1]) for box in boxes]
            valid_boxes = [(box, conf) for box, conf in zip(boxes, confidences) if conf > 0.7]
            if valid_boxes:
                areas = [(box[2] - box[0]) * (box[3] - box[1]) for box, _ in valid_boxes]
                max_idx = np.argmax(areas)
                boxes = [valid_boxes[max_idx][0]]
                print(f"DEBUG: Detected {len(valid_boxes)} persons, selected largest bbox with area {areas[max_idx]:.1f}")
            else:
                print("DEBUG: No valid boxes with confidence > 0.7")
                return pose_data

        for box in boxes:
            x1, y1, x2, y2 = map(int, box)
            if x2 <= x1 or y2 <= y1:
                continue
            cropped = image[y1:y2, x1:x2]
            if cropped.size == 0:
                continue

            cropped_rgb = cv2.cvtColor(cropped, cv2.COLOR_BGR2RGB)
            pose_results = self.pose.process(cropped_rgb)

            if pose_results.pose_landmarks:
                landmarks = pose_results.pose_landmarks.landmark
                center_x, center_y = self._calculate_body_center(pose_results.pose_landmarks.landmark)
                unit_length = self._calculate_unit_length(pose_results.pose_landmarks.landmark)
                keypoints = self._normalize_keypoints(pose_results.pose_landmarks.landmark, center_x, center_y, unit_length)

                if keypoints:
                    pose_data.append(PoseResult(
                        image_path=str(image_path),
                        bbox=[x1, y1, x2, y2],
                        keypoints=keypoints,
                        center_x=center_x,
                        center_y=center_y,
                        unit_length=unit_length,
                        frame_id=os.path.basename(image_path).split('_')[-1].split('.')[0]
                    ))
        return pose_data

    def process_image(self, image_path):
        image_path = Path(image_path)
        image = cv2.imread(str(image_path))
        if image is None:
            print(f"Не удалось загрузить изображение: {image_path}")
            return None

        detection_results = self.yolo(image)
        keypoints_data = []

        for detection in detection_results:
            keypoints_data.extend(self._extract_pose_data(detection, image, image_path))

        return keypoints_data if keypoints_data else None

    def process_video_frames(self, frames_dir, output_csv):
        frames_dir = Path(frames_dir)
        output_csv = Path(output_csv)
        output_csv.parent.mkdir(parents=True, exist_ok=True)

        image_files = sorted(list(frames_dir.glob('*.png')), key=lambda x: int(x.stem.split('_')[-1]))

        all_pose_results = []
        
        # Папка для сохранения кадров со скелетом
        skeleton_output_dir = frames_dir.parent / 'skeleton_frames'
        skeleton_output_dir.mkdir(parents=True, exist_ok=True)

        for img_file in tqdm(image_files, desc="Обработка кадров видео"):
            try:
                image = cv2.imread(str(img_file))
                if image is None:
                    continue
                    
                results = self.process_image(img_file)
                if results:
                    all_pose_results.extend(results)
                    
                    # Рисуем скелет на кадре
                    for result in results:
                        # Денормализуем координаты
                        keypoints_denorm = self._denormalize_keypoints(
                            result.keypoints,
                            result.center_x,
                            result.center_y,
                            result.unit_length,
                            result.bbox,
                            image.shape
                        )
                        
                        # Рисуем скелет
                        frame_with_skeleton = self.draw_skeleton(image.copy(), keypoints_denorm)
                        
                        # Сохраняем кадр
                        output_frame_path = skeleton_output_dir / f"skeleton_{img_file.stem}.jpg"
                        cv2.imwrite(str(output_frame_path), frame_with_skeleton)
                        
            except Exception as e:
                print(f"Ошибка обработки {img_file}: {e}")
                continue

        if all_pose_results:
            self._write_to_csv(output_csv, all_pose_results)
            print(f"Кадры со скелетом сохранены в: {skeleton_output_dir}")

    def _write_to_csv(self, output_csv, pose_results):
        with open(output_csv, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['frame_id', 'image_path', 'bbox', 'landmark', 'x_norm', 'y_norm', 'visibility', 'center_x', 'center_y', 'unit_length'])

            for result in pose_results:
                for landmark_name, coords in result.keypoints.items():
                    writer.writerow([
                        result.frame_id,
                        result.image_path,
                        result.bbox,
                        landmark_name,
                        coords['x_norm'],
                        coords['y_norm'],
                        coords['visibility'],
                        result.center_x,
                        result.center_y,
                        result.unit_length
                    ])

    def draw_skeleton(self, frame, keypoints):
        """Рисует скелет на кадре"""
        overlay = frame.copy()
        
        connections = [
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
        
        skeleton_color = (0, 255, 0)
        
        # Рисуем линии скелета
        for start, end in connections:
            if start in keypoints and end in keypoints:
                pt1 = tuple(map(int, keypoints[start]))
                pt2 = tuple(map(int, keypoints[end]))
                cv2.line(overlay, pt1, pt2, skeleton_color, 3)
        
        # Рисуем ключевые точки (суставы)
        for landmark, point in keypoints.items():
            x, y = int(point[0]), int(point[1])
            cv2.circle(overlay, (x, y), 8, skeleton_color, -1)
            cv2.circle(overlay, (x, y), 8, (255, 255, 255), 2)
        
        result = cv2.addWeighted(overlay, 0.7, frame, 0.3, 0)
        
        return result

    def _denormalize_keypoints(self, keypoints_norm, center_x, center_y, unit_length, bbox, image_shape):
        # Денормализует ключевые точки обратно в пиксели изображения
        x1, y1, x2, y2 = bbox
        keypoints_denorm = {}
        
        for name, coords in keypoints_norm.items():
            x_norm = coords['x_norm']
            y_norm = coords['y_norm']
            
            x_pixel = x1 + (center_x + x_norm * unit_length) * (x2 - x1)
            y_pixel = y1 + (center_y + y_norm * unit_length) * (y2 - y1)
            
            # Ограничиваем координаты границами bbox
            x_pixel = max(x1, min(x_pixel, x2))
            y_pixel = max(y1, min(y_pixel, y2))
            
            keypoints_denorm[name] = (x_pixel, y_pixel)
        
        return keypoints_denorm

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Извлечение поз для фитнес-анализа")
    parser.add_argument('--frames_dir', help="Папка с кадрами видео")
    parser.add_argument('--output_csv', default='data/annotations/video_pose_data.csv')
    args = parser.parse_args()
    if args.frames_dir:
        extractor = FitnessPoseExtractor()
        extractor.process_video_frames(args.frames_dir, args.output_csv)