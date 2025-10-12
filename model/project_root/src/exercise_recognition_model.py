import os
import csv
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import yaml
from pathlib import Path
import joblib
from sklearn.preprocessing import LabelEncoder

class ExerciseClassifier:
    def __init__(self, config_path=None, model_path=None):
        if config_path is None:
            config_path = str(Path(__file__).parent.parent / 'config/config.yaml')
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f) or {}
        model_config = config.get('model', {})
        self.model = RandomForestClassifier(
            n_estimators=model_config.get('n_estimators', 100),
            max_depth=model_config.get('max_depth', 10),
            random_state=model_config.get('random_state', 42)
        )
        self.feature_names = model_config.get('features', ['x_norm', 'y_norm', 'visibility', 'center_x', 'center_y', 'unit_length'])
        self.exercise_types = model_config.get('exercise_types', ['unknown', 'squat', 'push_up', 'long_jump'])
        self.correctness_thresholds = model_config.get('correctness_thresholds', {'min_visibility': 0.5})
        self.correctness_model = RandomForestClassifier(
            n_estimators=100, max_depth=10, random_state=42
        )
        self.model_path = model_path or str(Path(__file__).parent.parent / 'models/exercise_classifier.joblib')
        self.label_encoder = LabelEncoder()
        self.label_encoder.fit(self.exercise_types)

        # Пытаемся загрузить сохранённую модель
        if os.path.exists(self.model_path):
            try:
                loaded_data = joblib.load(self.model_path)
                if isinstance(loaded_data, tuple):
                    if len(loaded_data) == 2:  # Старый формат: только модели
                        self.model, self.correctness_model = loaded_data
                        print(f"Загружена старая модель из {self.model_path}")
                    elif len(loaded_data) == 3:  # Новый формат: модели + LabelEncoder
                        self.model, self.correctness_model, self.label_encoder = loaded_data
                        print(f"Загружена полная модель из {self.model_path}")
                else:
                    raise ValueError("Неверный формат сохранённой модели")
            except Exception as e:
                print(f"Ошибка при загрузке модели: {e}")
                # Создаём новые модели
                self.model = RandomForestClassifier()
                self.correctness_model = RandomForestClassifier()
        else:
            print(f"Модель не найдена в {self.model_path}, будет создана новая")

    def extract_features(self, row):
        features = []
        for feature in self.feature_names:
            if feature in row:
                features.append(float(row[feature]))
            else:
                features.append(0.0)
        return np.array(features)

    def prepare_data(self, csv_path):
        X, y_exercise, y_correctness = [], [], []
        with open(csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                features = self.extract_features(row)
                if len(features) == len(self.feature_names):
                    X.append(features)
                    exercise_type = row.get('exercise_type', 'unknown')
                    y_exercise.append(exercise_type)
                    is_correct = int(row.get('is_correct', 0))
                    y_correctness.append(is_correct)
        return np.array(X), np.array(y_exercise), np.array(y_correctness)

    def train(self, csv_path):
        X, y_exercise, y_correctness = self.prepare_data(csv_path)
        if len(X) == 0 or len(y_exercise) == 0 or len(y_correctness) == 0:
            raise ValueError("Недостаточно данных для обучения модели")

        X_train, X_test, y_exercise_train, y_exercise_test, y_correctness_train, y_correctness_test = train_test_split(
            X, y_exercise, y_correctness, test_size=0.2, random_state=42
        )

        # Преобразуем метки упражнений
        y_exercise_train_encoded = self.label_encoder.transform(y_exercise_train)
        y_exercise_test_encoded = self.label_encoder.transform(y_exercise_test)

        # Обучаем модели
        self.model.fit(X_train, y_exercise_train_encoded)
        self.correctness_model.fit(X_train, y_correctness_train)

        # Оцениваем точность
        exercise_accuracy = accuracy_score(y_exercise_test_encoded, self.model.predict(X_test))
        correctness_accuracy = accuracy_score(y_correctness_test, self.correctness_model.predict(X_test))
        
        print(f"Точность классификации упражнений: {exercise_accuracy:.2f}")
        print(f"Точность классификации правильности: {correctness_accuracy:.2f}")

        # Сохраняем модели и энкодер
        joblib.dump((self.model, self.correctness_model, self.label_encoder), self.model_path)
        print(f"Модель сохранена в {self.model_path}")

    def predict(self, X):
        try:
            exercise_preds_encoded = self.model.predict(X)
            correctness_preds = self.correctness_model.predict(X)
            exercise_preds = self.label_encoder.inverse_transform(exercise_preds_encoded)
            return list(zip(exercise_preds, correctness_preds))
        except Exception as e:
            print(f"Ошибка при предсказании: {e}")
            return [('unknown', False)] * len(X)

def train_exercise_classifier(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    classifier.train(csv_path)
    return classifier

def infer_exercise(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    X, _, _ = classifier.prepare_data(csv_path)
    if len(X) == 0:
        return [{'frame_id': i, 'exercise_type': 'unknown', 'correctness': 'unknown'} for i in range(10)]
    
    preds = classifier.predict(X)
    results = []
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            frame_id = int(row['frame_id'])
            exercise_type, is_correct = preds[i]
            correctness = 'correct' if is_correct else 'incorrect'
            results.append({
                'frame_id': frame_id,
                'exercise_type': exercise_type,
                'correctness': correctness
            })
    return results

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
            print(pred)