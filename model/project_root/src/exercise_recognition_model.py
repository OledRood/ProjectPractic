import os
import csv
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.exceptions import NotFittedError
from sklearn.metrics import accuracy_score
import yaml
from pathlib import Path
import joblib
from collections import defaultdict
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('pipeline.log')
    ]
)
logger = logging.getLogger(__name__)

class BiLSTMClassifier(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers, num_classes, dropout=0.2):
        super(BiLSTMClassifier, self).__init__()
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers, bidirectional=True, batch_first=True, dropout=dropout)
        self.fc = nn.Linear(hidden_size * 2, num_classes)

    def forward(self, x):
        _, (h_n, _) = self.lstm(x)
        h_n = torch.cat((h_n[-2,:,:], h_n[-1,:,:]), dim=1)
        return self.fc(h_n)

class ExerciseClassifier:
    def __init__(self, config_path=None, model_path=None):
        if config_path is None:
            config_path = str(Path(__file__).parent.parent / 'config/config.yaml')
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f) or {}
        model_config = config.get('model', {})
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.hidden_size = model_config.get('hidden_size', 128)
        self.num_layers = model_config.get('num_layers', 2)
        self.dropout = model_config.get('dropout', 0.2)
        self.max_seq_len = model_config.get('max_seq_len', 100)
        self.landmark_order = model_config.get('landmarks', ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'LEFT_HIP', 'RIGHT_HIP', 'LEFT_ELBOW', 'RIGHT_ELBOW', 'LEFT_WRIST', 'RIGHT_WRIST', 'LEFT_KNEE', 'RIGHT_KNEE', 'LEFT_ANKLE', 'RIGHT_ANKLE'])
        self.exercise_types = model_config.get('exercise_types', ['pushup', 'squat', 'long_jump', 'unknown'])
        self.num_classes = len(self.exercise_types)
        self.correctness_thresholds = model_config.get('correctness_thresholds', {
            'min_visibility': 0.5,
            'squat_knee_angle_min': 90,
            'pushup_elbow_angle_min': 90,
            'long_jump_takeoff_angle_min': 25,
            'long_jump_takeoff_angle_max': 40,
            'long_jump_ankle_separation_max': 0.3
        })
        self.heuristic_thresholds = model_config.get('heuristic_thresholds', {
            'horizontal_delta_max': 0.1,
            'vertical_delta_max': 0.15,
            'knee_angle_min': 90,
            'elbow_angle_min': 90,
            'bilstm_confidence_min': 0.7
        })
        self.model_path = model_path or str(Path(__file__).parent.parent / 'models/exercise_classifier.pth')
        self.scaler_path = str(Path(self.model_path).parent / 'scaler.joblib')
        self.label_encoder = LabelEncoder()
        self.label_encoder.fit(self.exercise_types)
        self.scaler = StandardScaler()
        self.scaler_fitted = False
        self.model = None
        self.load_model()

    def load_model(self):
        if os.path.exists(self.model_path) and os.path.exists(self.scaler_path):
            self.scaler = joblib.load(self.scaler_path)
            self.scaler_fitted = True
            self.model = BiLSTMClassifier(
                input_size=106,  # Фиксируем размер входных данных
                hidden_size=self.hidden_size,
                num_layers=self.num_layers,
                num_classes=self.num_classes,
                dropout=self.dropout
            ).to(self.device)
            self.model.load_state_dict(torch.load(self.model_path))
            self.model.eval()
            logger.info(f"Загружена модель из {self.model_path} и scaler из {self.scaler_path}")
        else:
            logger.info("Модель или scaler не найдены, будет использоваться эвристика")

    def _calculate_angle(self, p1, p2, p3):
        v1 = np.array(p1) - np.array(p2)
        v2 = np.array(p3) - np.array(p2)
        angle = np.arccos(np.clip(np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2)), -1.0, 1.0))
        return np.degrees(angle) if not np.isnan(angle) else 0.0

    def _calculate_distance(self, p1, p2):
        return np.linalg.norm(np.array(p1) - np.array(p2))

    def extract_frame_features(self, frame_data):
        keypoints = {kp['landmark']: (kp['x_norm'], kp['y_norm'], kp['visibility']) for kp in frame_data}
        features = []
        for lm in self.landmark_order:
            if lm in keypoints:
                x, y, vis = keypoints[lm]
                features.extend([x, y, vis])
            else:
                features.extend([0.0, 0.0, 0.0])

        features.extend([frame_data[0]['center_x'], frame_data[0]['center_y'], frame_data[0]['unit_length']])

        angles = []
        angle_triplets = [
            ('LEFT_HIP', 'LEFT_SHOULDER', 'LEFT_ELBOW'), ('RIGHT_HIP', 'RIGHT_SHOULDER', 'RIGHT_ELBOW'),
            ('LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST'), ('RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST'),
            ('LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE'), ('RIGHT_HIP', 'RIGHT_KNEE', 'RIGHT_ANKLE'),
            ('LEFT_SHOULDER', 'LEFT_HIP', 'LEFT_KNEE'), ('RIGHT_SHOULDER', 'RIGHT_HIP', 'RIGHT_KNEE')
        ]
        for t in angle_triplets:
            if all(lm in keypoints for lm in t):
                angles.append(self._calculate_angle(keypoints[t[0]][:2], keypoints[t[1]][:2], keypoints[t[2]][:2]))
            else:
                angles.append(0.0)
        features.extend(angles)

        pairs = [('LEFT_SHOULDER', 'RIGHT_SHOULDER'), ('LEFT_HIP', 'RIGHT_HIP'), ('LEFT_KNEE', 'RIGHT_KNEE'),
                 ('LEFT_ELBOW', 'RIGHT_ELBOW'), ('LEFT_WRIST', 'RIGHT_WRIST'), ('LEFT_ANKLE', 'RIGHT_ANKLE')]
        distances = []
        for p in pairs:
            if all(lm in keypoints for lm in p):
                distances.append(self._calculate_distance(keypoints[p[0]][:2], keypoints[p[1]][:2]))
            else:
                distances.append(0.0)
        features.extend(distances)

        return np.array(features)

    def prepare_sequences(self, csv_path, for_training=True):
        frame_groups = defaultdict(list)
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                frame_id = row['frame_id']
                frame_groups[frame_id].append({
                    'landmark': row['landmark'],
                    'x_norm': float(row['x_norm']),
                    'y_norm': float(row['y_norm']),
                    'visibility': float(row['visibility']),
                    'center_x': float(row['center_x']),
                    'center_y': float(row['center_y']),
                    'unit_length': float(row['unit_length']),
                    'exercise_type': row.get('exercise_type', 'unknown') if for_training else 'unknown',
                    'is_correct': int(row.get('is_correct', 0)) if for_training else 0
                })

        sorted_frames = sorted(frame_groups.keys(), key=int)
        if not sorted_frames:
            logger.error(f"DEBUG: No frames loaded from {csv_path}")
            return None, None, None, frame_groups

        logger.info(f"DEBUG: frame_groups structure for frame {sorted_frames[0]}: {frame_groups[sorted_frames[0]]}")

        seq_features = [self.extract_frame_features(frame_groups[fid]) for fid in sorted_frames]
        seq_features = np.array(seq_features)

        if len(seq_features) > 1:
            deltas = np.diff(seq_features, axis=0)
            deltas = np.pad(deltas, ((0, 1), (0, 0)))
            seq_features = np.hstack((seq_features, deltas))

        if len(seq_features) > self.max_seq_len:
            seq_features = seq_features[:self.max_seq_len]
        elif len(seq_features) < self.max_seq_len:
            pad = np.zeros((self.max_seq_len - len(seq_features), seq_features.shape[1]))
            seq_features = np.vstack((seq_features, pad))

        try:
            if for_training:
                seq_features = self.scaler.fit_transform(seq_features)
                self.scaler_fitted = True
            elif self.scaler_fitted:
                seq_features = self.scaler.transform(seq_features)
            else:
                logger.info("DEBUG: Scaler not fitted, skipping normalization")
        except NotFittedError:
            logger.info("DEBUG: Scaler not fitted, skipping normalization")
            seq_features = seq_features

        exercise_label = None
        correctness_label = None
        if for_training and frame_groups[sorted_frames[0]]:
            exercise_type = frame_groups[sorted_frames[0]][0].get('exercise_type', 'unknown')
            exercise_label = self.label_encoder.transform([exercise_type])[0]
            correctness_label = frame_groups[sorted_frames[0]][0].get('is_correct', 0)

        logger.info(f"DEBUG: Loaded {len(sorted_frames)} frames from {csv_path}, shape={seq_features.shape}, exercise_label={exercise_label}, correctness_label={correctness_label}")
        return seq_features, exercise_label, correctness_label, frame_groups

    def train(self, csv_path):
        seq, exercise_y, correct_y, _ = self.prepare_sequences(csv_path)
        if seq is None:
            raise ValueError(f"Не удалось загрузить данные из {csv_path}")

        input_size = seq.shape[-1]
        self.model = BiLSTMClassifier(
            input_size=input_size,
            hidden_size=self.hidden_size,
            num_layers=self.num_layers,
            num_classes=self.num_classes,
            dropout=self.dropout
        ).to(self.device)

        X = torch.from_numpy(seq).unsqueeze(0).float().to(self.device)
        y_exercise = torch.tensor([exercise_y], dtype=torch.long).to(self.device)

        optimizer = torch.optim.Adam(self.model.parameters(), lr=0.001)
        criterion = nn.CrossEntropyLoss()

        self.model.train()
        for epoch in range(50):
            optimizer.zero_grad()
            output = self.model(X)
            loss = criterion(output, y_exercise)
            loss.backward()
            optimizer.step()
            logger.info(f"Epoch {epoch}, Loss: {loss.item()}")

        torch.save(self.model.state_dict(), self.model_path)
        joblib.dump(self.scaler, self.scaler_path)
        logger.info(f"Модель обучена и сохранена в {self.model_path}")
        self.load_model()  # Загружаем модель после обучения

    def predict(self, seq_features, frame_groups):
        if not frame_groups or seq_features is None:
            logger.info("DEBUG: frame_groups is empty or seq_features is None")
            return 'unknown', 'unknown'

        sorted_frames = sorted(frame_groups.keys(), key=int)
        logger.info(f"DEBUG: Processing {len(sorted_frames)} frames")

        max_prob = 0.0
        exercise_pred = 0
        if self.model is not None and self.scaler_fitted:
            self.model.eval()
            with torch.no_grad():
                X = torch.from_numpy(seq_features).unsqueeze(0).float().to(self.device)
                output = self.model(X)
                probs = torch.softmax(output, dim=1).cpu().numpy()[0]
                exercise_pred = np.argmax(probs)
                max_prob = probs[exercise_pred]
        else:
            logger.info("DEBUG: No model or scaler found, using heuristic only")
            exercise_type = 'unknown'

        all_visibilities = []
        all_knee_angles = []
        all_elbow_angles = []
        all_hip_deltas_x = []
        all_hip_deltas_y = []
        all_ankle_separations = []
        all_takeoff_angles = []
        all_torso_angles = []

        for i, frame_id in enumerate(sorted_frames):
            frame_data = frame_groups[frame_id]
            visibilities = [fd['visibility'] for fd in frame_data]
            all_visibilities.extend(visibilities)
            keypoints = {kp['landmark']: (kp['x_norm'], kp['y_norm']) for kp in frame_data}

            if all(lm in keypoints for lm in ['LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE']):
                knee_angle = self._calculate_angle(keypoints['LEFT_HIP'], keypoints['LEFT_KNEE'], keypoints['LEFT_ANKLE'])
                all_knee_angles.append(knee_angle)
            if all(lm in keypoints for lm in ['RIGHT_HIP', 'RIGHT_KNEE', 'RIGHT_ANKLE']):
                knee_angle = self._calculate_angle(keypoints['RIGHT_HIP'], keypoints['RIGHT_KNEE'], keypoints['RIGHT_ANKLE'])
                all_knee_angles.append(knee_angle)

            if all(lm in keypoints for lm in ['LEFT_SHOULDER', 'LEFT_ELBOW', 'LEFT_WRIST']):
                elbow_angle = self._calculate_angle(keypoints['LEFT_SHOULDER'], keypoints['LEFT_ELBOW'], keypoints['LEFT_WRIST'])
                all_elbow_angles.append(elbow_angle)
            if all(lm in keypoints for lm in ['RIGHT_SHOULDER', 'RIGHT_ELBOW', 'RIGHT_WRIST']):
                elbow_angle = self._calculate_angle(keypoints['RIGHT_SHOULDER'], keypoints['RIGHT_ELBOW'], keypoints['RIGHT_WRIST'])
                all_elbow_angles.append(elbow_angle)

            if 'LEFT_ANKLE' in keypoints and 'RIGHT_ANKLE' in keypoints:
                ankle_sep = self._calculate_distance(keypoints['LEFT_ANKLE'], keypoints['RIGHT_ANKLE'])
                all_ankle_separations.append(ankle_sep)

            if i > 0:
                prev_keypoints = {kp['landmark']: (kp['x_norm'], kp['y_norm']) for kp in frame_groups[sorted_frames[i-1]]}
                if all(lm in keypoints and lm in prev_keypoints for lm in ['LEFT_HIP', 'RIGHT_HIP']):
                    delta_x_left = keypoints['LEFT_HIP'][0] - prev_keypoints['LEFT_HIP'][0]
                    delta_x_right = keypoints['RIGHT_HIP'][0] - prev_keypoints['RIGHT_HIP'][0]
                    delta_y_left = keypoints['LEFT_HIP'][1] - prev_keypoints['LEFT_HIP'][1]
                    delta_y_right = keypoints['RIGHT_HIP'][1] - prev_keypoints['RIGHT_HIP'][1]
                    all_hip_deltas_x.append(np.mean([abs(delta_x_left), abs(delta_x_right)]))
                    all_hip_deltas_y.append(np.mean([abs(delta_y_left), abs(delta_y_right)]))

            # Torso angle: angle between shoulder-midpoint and hip-midpoint relative to horizontal
            if all(lm in keypoints for lm in ['LEFT_SHOULDER', 'RIGHT_SHOULDER', 'LEFT_HIP', 'RIGHT_HIP']):
                sh_x = (keypoints['LEFT_SHOULDER'][0] + keypoints['RIGHT_SHOULDER'][0]) / 2.0
                sh_y = (keypoints['LEFT_SHOULDER'][1] + keypoints['RIGHT_SHOULDER'][1]) / 2.0
                hip_x = (keypoints['LEFT_HIP'][0] + keypoints['RIGHT_HIP'][0]) / 2.0
                hip_y = (keypoints['LEFT_HIP'][1] + keypoints['RIGHT_HIP'][1]) / 2.0
                # angle in degrees relative to horizontal: 0 means horizontal torso
                raw_angle = np.degrees(np.arctan2(hip_y - sh_y, hip_x - sh_x))
                angle_abs = abs(raw_angle)
                # Normalize to [0, 90]: if angle > 90, take supplementary to get smallest angle to horizontal
                if angle_abs > 90:
                    angle_abs = 180.0 - angle_abs
                all_torso_angles.append(angle_abs)

            if all(lm in keypoints for lm in ['LEFT_HIP', 'LEFT_KNEE', 'LEFT_ANKLE']):
                takeoff_angle = self._calculate_angle(keypoints['LEFT_HIP'], keypoints['LEFT_KNEE'], keypoints['LEFT_ANKLE'])
                all_takeoff_angles.append(takeoff_angle)

        avg_visibility = np.mean(all_visibilities) if all_visibilities else 0.0
        min_knee_angle = np.min(all_knee_angles) if all_knee_angles else 180.0
        min_elbow_angle = np.min(all_elbow_angles) if all_elbow_angles else 180.0
        max_hip_delta_x = np.max(all_hip_deltas_x) if all_hip_deltas_x else 0.0
        max_hip_delta_y = np.max(all_hip_deltas_y) if all_hip_deltas_y else 0.0
        max_ankle_sep = np.max(all_ankle_separations) if all_ankle_separations else 0.0
        avg_takeoff_angle = np.mean(all_takeoff_angles) if all_takeoff_angles else 0.0
        avg_torso_angle = np.mean(all_torso_angles) if all_torso_angles else 0.0

        # Применяем эвристики всегда, независимо от уверенности модели
        # Проверяем характерные признаки прыжка в длину
        # Учитываем все необходимые условия, включая положение лодыжек
        is_likely_jump = (
            max_hip_delta_x >= self.heuristic_thresholds['horizontal_delta_max'] and  # Достаточное горизонтальное движение
            max_hip_delta_y >= self.heuristic_thresholds['vertical_delta_max'] * 0.7 and  # Заметное вертикальное движение
            min_knee_angle <= 90 and  # Сгибание колен перед прыжком
            max_hip_delta_y >= max_hip_delta_x * 0.3 and  # Наличие вертикальной составляющей движения
            max_ankle_sep <= self.correctness_thresholds['long_jump_ankle_separation_max'] and  # Проверяем расстояние между лодыжками
            15 <= avg_takeoff_angle <= 150  # Более гибкая проверка угла отталкивания
        )
        
        # Проверяем характерные признаки приседания
        # Ослабляем порог вертикального движения (умножитель 0.15) чтобы учесть неглубокие, но явные приседания
        is_likely_squat = (
            min_knee_angle <= 120 and  # Более лояльное требование к сгибанию колен
            avg_torso_angle >= 70 and   # Корпус достаточно вертикальный
            max_hip_delta_y >= self.heuristic_thresholds['vertical_delta_max'] * 0.15 and  # Есть вертикальное движение (более гибкий порог)
            max_hip_delta_x <= self.heuristic_thresholds['horizontal_delta_max'] * 2.0 and  # Ограничиваем горизонтальное движение
            max_hip_delta_y >= max_hip_delta_x * 0.4 and  # Для приседания вертикальное движение должно быть значительнее горизонтального
            max_hip_delta_x <= 0.2  # Жесткое ограничение на горизонтальное движение для исключения ходьбы
        )
        
        # Проверяем характерные признаки отжимания
        pushup_min_knee = self.correctness_thresholds.get('pushup_knee_angle_min', 110)  # Берем значение из конфига
        is_likely_pushup = (
            min_elbow_angle < self.heuristic_thresholds['elbow_angle_min'] and  # Сгибание локтей
            min_knee_angle > pushup_min_knee and  # Ноги должны быть относительно прямыми
            avg_torso_angle < 35 and  # Корпус должен быть почти параллелен полу
            max_hip_delta_y >= self.heuristic_thresholds['vertical_delta_max'] * 0.8  # Достаточная амплитуда движения
        )
        
        # Приоритезируем определение прыжка в длину по физическим характеристикам движения
        if is_likely_jump:
            exercise_type = 'long_jump'
        elif is_likely_squat:
            exercise_type = 'squat'
        elif is_likely_pushup:
            exercise_type = 'pushup'
        else:
            # Используем предсказание модели только если эвристики не дали результата
            if max_prob >= self.heuristic_thresholds['bilstm_confidence_min']:
                exercise_type = self.label_encoder.inverse_transform([exercise_pred])[0]
            else:
                exercise_type = 'unknown'
        
        logger.info(f"DEBUG: Movement characteristics: is_likely_jump={is_likely_jump}, " 
                   f"is_likely_squat={is_likely_squat}, is_likely_pushup={is_likely_pushup}")

        # Базовая корректность по видимости
        correctness = 'correct' if avg_visibility > self.correctness_thresholds['min_visibility'] else 'incorrect'

        # Вычисляем диагностические флаги для всех типов (логируем всегда для удобства отладки)
        # Squat diagnostics
        squat_has_good_knee_bend = min_knee_angle <= self.correctness_thresholds['squat_knee_angle_min']
        squat_has_vertical_movement = True  # Убираем строгую проверку вертикального движения
        squat_has_stable_position = max_hip_delta_x <= self.heuristic_thresholds['horizontal_delta_max']
        squat_has_symmetric_stance = True  # Делаем проверку симметрии более лояльной

        # Получаем пороги из конфига для подробных логов
        squat_knee_threshold = self.correctness_thresholds.get('squat_knee_correct_threshold', 120)
        squat_knee_min = self.correctness_thresholds.get('squat_knee_angle_min', 140)
        
        logger.info(f"DEBUG: Squat diagnostics - "
                   f"knee_bend: {squat_has_good_knee_bend} (min_knee={min_knee_angle:.1f}° <= {squat_knee_min}°), "
                   f"vertical_movement: {squat_has_vertical_movement} (delta_y={max_hip_delta_y:.3f} >= {self.heuristic_thresholds['vertical_delta_max']*0.5:.3f}), "
                   f"stable_position: {squat_has_stable_position} (delta_x={max_hip_delta_x:.3f} <= {self.heuristic_thresholds['horizontal_delta_max']:.3f}), "
                   f"symmetric_stance: {squat_has_symmetric_stance}, "
                   f"torso_angle: {avg_torso_angle:.1f}° (should be > 70°)")

        # Pushup diagnostics
        pushup_torso_threshold = self.heuristic_thresholds.get('pushup_torso_angle_max', 35)
        pushup_vertical_multiplier = self.heuristic_thresholds.get('pushup_vertical_multiplier', 2)
        pushup_has_good_elbow_bend = min_elbow_angle <= self.correctness_thresholds['pushup_elbow_angle_min']
        pushup_has_straight_back = avg_torso_angle <= pushup_torso_threshold
        pushup_has_stable_position = (max_hip_delta_x <= self.heuristic_thresholds['horizontal_delta_max'] and
                                    max_hip_delta_y <= self.heuristic_thresholds['vertical_delta_max'] * pushup_vertical_multiplier)
        pushup_has_good_depth = max_hip_delta_y >= self.heuristic_thresholds['vertical_delta_max'] * 0.5
        pushup_min_knee = self.correctness_thresholds.get('pushup_knee_angle_min', 120)  # Берем минимальный угол для отжиманий из конфига

        logger.info(f"DEBUG: Pushup diagnostics - "
                   f"elbow_bend: {pushup_has_good_elbow_bend} (min_elbow={min_elbow_angle:.1f}° <= {self.correctness_thresholds['pushup_elbow_angle_min']}°), "
                   f"straight_back: {pushup_has_straight_back} (avg_torso_angle={avg_torso_angle:.1f}° <= {pushup_torso_threshold}°), "
                   f"stable_position: {pushup_has_stable_position} (delta_x={max_hip_delta_x:.3f} <= {self.heuristic_thresholds['horizontal_delta_max']:.3f}, "
                   f"delta_y={max_hip_delta_y:.3f} <= {self.heuristic_thresholds['vertical_delta_max']*pushup_vertical_multiplier:.3f}), "
                   f"good_depth: {pushup_has_good_depth} (delta_y={max_hip_delta_y:.3f} >= {self.heuristic_thresholds['vertical_delta_max']*0.5:.3f}), "
                   f"straight_legs: {min_knee_angle > pushup_min_knee} (min_knee={min_knee_angle:.1f}° > {pushup_min_knee}°)")

        # Long jump diagnostics
        jump_knee_min = 60  # Минимальный угол сгибания колен для прыжка
        jump_has_good_knee_bend = min_knee_angle <= jump_knee_min
        jump_has_good_takeoff = (self.correctness_thresholds['long_jump_takeoff_angle_min'] <= 
                                avg_takeoff_angle <= self.correctness_thresholds['long_jump_takeoff_angle_max'])
        jump_has_good_ankle_position = max_ankle_sep <= self.correctness_thresholds['long_jump_ankle_separation_max']
        jump_has_good_movement = max_hip_delta_x >= self.heuristic_thresholds['horizontal_delta_max']

        logger.info(f"DEBUG: Jump diagnostics - "
                   f"knee_bend: {jump_has_good_knee_bend} (min_knee={min_knee_angle:.1f}° <= {jump_knee_min}°), "
                   f"takeoff: {jump_has_good_takeoff} ({self.correctness_thresholds['long_jump_takeoff_angle_min']}° <= {avg_takeoff_angle:.1f}° <= {self.correctness_thresholds['long_jump_takeoff_angle_max']}°), "
                   f"ankle: {jump_has_good_ankle_position} (sep={max_ankle_sep:.3f} <= {self.correctness_thresholds['long_jump_ankle_separation_max']:.3f}), "
                   f"movement: {jump_has_good_movement} (delta_x={max_hip_delta_x:.3f} >= {self.heuristic_thresholds['horizontal_delta_max']:.3f})")

        # Определяем тип упражнения на основе диагностик и характерных признаков
        correctness = 'correct'  # По умолчанию считаем корректным

        # Проверяем каждое упражнение на корректность и характерные признаки
        pushup_correct = (all([pushup_has_good_elbow_bend, pushup_has_straight_back, pushup_has_stable_position, pushup_has_good_depth]) and
                          min_knee_angle > 120 and  # Ноги достаточно прямые
                          min_elbow_angle < self.heuristic_thresholds['elbow_angle_min'])  # Есть сгибание локтей

        # Более лояльные критерии корректности для приседания берём из конфига
        squat_knee_threshold = self.correctness_thresholds.get('squat_knee_correct_threshold', 120)
        # Убираем жёсткое требование по локтям для приседания — многие держат руки согнутыми
        squat_correct = (all([squat_has_good_knee_bend, squat_has_vertical_movement, squat_has_stable_position, squat_has_symmetric_stance]) and
                         min_knee_angle < squat_knee_threshold)  # Смягчённое требование по сгибанию колен

        jump_correct = all([jump_has_good_knee_bend, jump_has_good_takeoff, jump_has_good_ankle_position, jump_has_good_movement])

        # Определяем тип по характерным признакам движения и диагностике
        exercise_type = 'unknown'  # По умолчанию

        # В новой логике is_not_exercise не используется, так как мы проверяем наличие признаков упражнений
        is_not_exercise = False
        
        # Если нет явных признаков какого-либо упражнения, считаем это неупражнением
        if not any([is_likely_squat, is_likely_pushup, is_likely_jump]):
            exercise_type = 'unknown'
        else:
            # Используем характерные признаки движения как приоритет
            if is_likely_squat:  # Сначала проверяем приседание
                exercise_type = 'squat'
            elif is_likely_pushup:  # Затем отжимания
                exercise_type = 'pushup'
            elif is_likely_jump and jump_has_good_knee_bend:  # Прыжок только при хорошем сгибании колен
                exercise_type = 'long_jump'
            else:
                exercise_type = 'unknown'
            
            # Используем предсказание модели только если:
            # 1. Движение не определено как упражнение по эвристикам
            # 2. Модель уверена в своём предсказании
            # 3. Нет явных признаков других упражнений
            if exercise_type == 'unknown' and max_prob >= self.heuristic_thresholds['bilstm_confidence_min']:
                pred_label = self.label_encoder.inverse_transform([exercise_pred])[0]
                if pred_label != 'unknown' and not any([is_likely_squat, is_likely_pushup, is_likely_jump]):
                    exercise_type = pred_label

        # Проверяем корректность для выбранного типа
        # Для unknown не указываем корректность
        if exercise_type == 'unknown':
            correctness = 'unknown'
        else:
            if exercise_type == 'pushup' and not pushup_correct:
                correctness = 'incorrect'
            elif exercise_type == 'squat' and not squat_correct:
                correctness = 'incorrect'
            elif exercise_type == 'long_jump' and not jump_correct:
                correctness = 'incorrect'

        logger.info(f"DEBUG: Metrics: min_knee={min_knee_angle:.1f}, min_elbow={min_elbow_angle:.1f}, max_hip_delta_x={max_hip_delta_x:.3f}, max_hip_delta_y={max_hip_delta_y:.3f}, avg_takeoff={avg_takeoff_angle:.1f}, avg_torso_angle={avg_torso_angle:.1f}, max_ankle_sep={max_ankle_sep:.3f}, avg_visibility={avg_visibility:.3f}")

        return exercise_type, correctness

def train_exercise_classifier(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    classifier.train(csv_path)
    return classifier

def infer_exercise(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    seq_features, _, _, frame_groups = classifier.prepare_sequences(csv_path, for_training=False)
    exercise_type, correctness = classifier.predict(seq_features, frame_groups)
    # Возвращаем результат только если определено конкретное упражнение
    if exercise_type != 'unknown':
        return [{'frame_id': 'all', 'exercise_type': exercise_type, 'correctness': correctness}]
    return []  # Возвращаем пустой список если движение не определено как упражнение

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Обучение и инференс модели распознавания упражнений")
    parser.add_argument('--csv_path', required=True, help="Путь к CSV файлу с данными поз")
    parser.add_argument('--train', action='store_true', help="Запустить обучение модели")
    parser.add_argument('--infer', action='store_true', help="Запустить инференс модели")
    args = parser.parse_args()

    if args.train:
        train_exercise_classifier(args.csv_path)
    elif args.infer:
        predictions = infer_exercise(args.csv_path)
        for pred in predictions:
            logger.info(pred)