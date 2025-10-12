import os
import csv
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import yaml
from pathlib import Path
import joblib

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
        self.feature_names = model_config.get('features', ['x_norm', 'y_norm', 'visibility'])
        self.exercise_types = model_config.get('exercise_types', ['unknown'])
        self.correctness_thresholds = model_config.get('correctness_thresholds', {'min_visibility': 0.5})
        self.correctness_model = RandomForestClassifier(
            n_estimators=100, max_depth=10, random_state=42
        )
        self.model_path = model_path or str(Path(__file__).parent.parent / 'models/exercise_classifier.joblib')

        # Пытаемся загрузить сохранённую модель
        if os.path.exists(self.model_path):
            self.model, self.correctness_model = joblib.load(self.model_path)
            print(f"Загружена сохранённая модель из {self.model_path}")
        else:
            print(f"Модель не найдена в {self.model_path}, будет обучена заново")

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
                    frame_id = int(row['frame_id'])
                    # Простая эвристика для примера (нужно заменить на реальную логику)
                    y_exercise.append(self.exercise_types[frame_id % len(self.exercise_types)])  # Циклическое распределение
                    y_correctness.append(1 if float(row.get('visibility', 0)) > self.correctness_thresholds['min_visibility'] else 0)
        return np.array(X), np.array(y_exercise), np.array(y_correctness)

    def train(self, csv_path):
        X, y_exercise, y_correctness = self.prepare_data(csv_path)
        if len(X) == 0 or len(y_exercise) == 0 or len(y_correctness) == 0:
            raise ValueError("Недостаточно данных для обучения модели")

        X_train, X_test, y_exercise_train, y_exercise_test, y_correctness_train, y_correctness_test = train_test_split(
            X, y_exercise, y_correctness, test_size=0.2, random_state=42
        )

        self.model.fit(X_train, y_exercise_train)
        exercise_accuracy = accuracy_score(y_exercise_test, self.model.predict(X_test))
        print(f"Точность классификации упражнений: {exercise_accuracy:.2f}")

        self.correctness_model.fit(X_train, y_correctness_train)
        correctness_accuracy = accuracy_score(y_correctness_test, self.correctness_model.predict(X_test))
        print(f"Точность классификации правильности: {correctness_accuracy:.2f}")

        # Сохраняем обе модели
        joblib.dump((self.model, self.correctness_model), self.model_path)
        print(f"Модель сохранена в {self.model_path}")

    def predict(self, X):
        exercise_preds = self.model.predict(X)
        correctness_preds = self.correctness_model.predict(X)
        return list(zip(exercise_preds, correctness_preds))

def train_exercise_classifier(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    classifier.train(csv_path)
    return classifier

def infer_exercise(csv_path, config_path=None):
    classifier = ExerciseClassifier(config_path)
    # Обучаем модель, если она не была загружена
    if not os.path.exists(classifier.model_path):
        classifier.train(csv_path)
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