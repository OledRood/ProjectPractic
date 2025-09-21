import os
import csv
import cv2
import numpy as np
from pathlib import Path
from dataclasses import dataclass
from ultralytics import YOLO
import mediapipe as mp
from tqdm import tqdm

@dataclass
class PoseResult:
    image_path: str
    bbox: list
    keypoints: dict
    center_x: float
    center_y: float
    unit_length: float

class PoseProcessor:
    def __init__(self, yolo_model_path='yolo11n.pt'):
        self.yolo = YOLO(yolo_model_path)
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose(
            static_image_mode=True,
            model_complexity=2,
            min_detection_confidence=0.5
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
        ls = landmarks[self.mp_pose.PoseLandmark.LEFT_SHOULDER.value]
        rb = landmarks[self.mp_pose.PoseLandmark.RIGHT_HIP.value]
        rs = landmarks[self.mp_pose.PoseLandmark.RIGHT_SHOULDER.value]
        lb = landmarks[self.mp_pose.PoseLandmark.LEFT_HIP.value]

        if ls.visibility < 0.5 or rb.visibility < 0.5 or rs.visibility < 0.5 or lb.visibility < 0.5:
            return 0.1  # Резервная единица длины

        diag1 = np.hypot(ls.x - rb.x, ls.y - rb.y)
        diag2 = np.hypot(rs.x - lb.x, rs.y - lb.y)
        return max((diag1 + diag2) / 2, 0.01)

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
                        unit_length=unit_length
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

    def _write_to_csv(self, output_csv, pose_results, class_name):
        with open(output_csv, 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(['image_path', 'bbox', 'landmark', 'x_norm', 'y_norm', 'visibility', 'class', 'center_x', 'center_y', 'unit_length'])

            for result in pose_results:
                for landmark_name, coords in result.keypoints.items():
                    writer.writerow([
                        result.image_path,
                        result.bbox,
                        landmark_name,
                        coords['x_norm'],
                        coords['y_norm'],
                        coords['visibility'],
                        class_name,
                        result.center_x,
                        result.center_y,
                        result.unit_length
                    ])

    def process_class_directory(self, class_dir, output_csv):
        class_dir = Path(class_dir)
        output_csv = Path(output_csv)
        output_csv.parent.mkdir(parents=True, exist_ok=True)

        class_name = class_dir.name
        image_files = list(class_dir.glob('**/*.jpg')) + list(class_dir.glob('**/*.jpeg')) + list(class_dir.glob('**/*.png'))

        all_pose_results = []

        for img_file in tqdm(image_files, desc=f"Обработка {class_name}"):
            try:
                results = self.process_image(img_file)
                if results:
                    all_pose_results.extend(results)
            except Exception as e:
                print(f"Ошибка обработки {img_file}: {e}")
                continue

        if all_pose_results:
            self._write_to_csv(output_csv, all_pose_results, class_name)