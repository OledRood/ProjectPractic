import torch
import torch.nn as nn
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.preprocessing import StandardScaler
import joblib
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class BiLSTMClassifier(nn.Module):
    def __init__(self, input_size=68, hidden_size=256, num_layers=2, num_classes=2, dropout=0.3):
        super(BiLSTMClassifier, self).__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        
        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            batch_first=True,
            bidirectional=True,
            dropout=dropout if num_layers > 1 else 0
        )
        
        self.dropout = nn.Dropout(dropout)
        self.fc1 = nn.Linear(hidden_size * 2, 128)
        self.fc2 = nn.Linear(128, num_classes)
        self.relu = nn.ReLU()
        
    def forward(self, x):
        # x shape: (batch_size, seq_len, input_size)
        lstm_out, _ = self.lstm(x)
        # lstm_out shape: (batch_size, seq_len, hidden_size * 2)
        
        # Берем последний выход
        last_output = lstm_out[:, -1, :]
        
        x = self.dropout(last_output)
        x = self.fc1(x)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc2(x)
        
        return x


class ExerciseRecognitionModel:
    def __init__(self, device='cpu'):
        self.device = device
        self.model = None
        self.scaler = None
        self.label_encoder = LabelEncoder()
        self.scaler_fitted = False
        self.classes_ = None
    
    def load_model(self, model_path, scaler_path):
# загрузка модели и scaler
        self.model = BiLSTMClassifier(
            input_size=68,      # ← Было 34, должно быть 68
            hidden_size=256,    # ← Было 64, должно быть 256
            num_classes=2, 
            num_layers=2
        )
        
        checkpoint = torch.load(model_path, map_location=self.device, weights_only=False)
        self.model.load_state_dict(checkpoint['model_state'])
        self.model.eval()
        
        self.scaler = joblib.load(scaler_path)
        
        if 'classes' in checkpoint:
            self.classes_ = checkpoint['classes']
        else:
            self.classes_ = np.array(['pushup', 'pullup'])
        
        logger.info(f"Модель загружена: {model_path}")
        logger.info(f"Классы: {self.classes_}\n")
    
    def create_sequences(self, features, seq_length=30):
        sequences = []
        for i in range(len(features) - seq_length + 1):
            sequences.append(features[i:i + seq_length])
        return np.array(sequences) if sequences else None
    
    def predict(self, pose_csv_path):
        # Предсказывает упражнение по CSV с позами
        import csv
        from collections import defaultdict
        
        if self.model is None:
            logger.error("Модель не загружена!")
            return []
        
        # Читаем CSV с позами
        frame_data = defaultdict(list)
        with open(pose_csv_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                frame_id = int(row['frame_id'])
                landmark = row['landmark']
                x_norm = float(row['x_norm'])
                y_norm = float(row['y_norm'])
                frame_data[frame_id].append([x_norm, y_norm])
        
        if not frame_data:
            logger.warning("Нет данных поз в CSV")
            return []
        
        # Сортируем по frame_id
        sorted_frames = sorted(frame_data.keys())
        total_frames = len(sorted_frames)
        logger.info(f"📊 Всего кадров в CSV: {total_frames}")
        
        # ВАЛИДАЦИЯ: если кадров слишком мало, это не упражнение
        MIN_FRAMES_REQUIRED = 50  # Минимум 50 кадров для упражнения
        if total_frames < MIN_FRAMES_REQUIRED:
            logger.warning(f"Слишком мало кадров ({total_frames} < {MIN_FRAMES_REQUIRED})")
            logger.info("Возвращаю 'unknown' - недостаточно данных")
            return [{
                'exercise': 'unknown',
                'confidence': 100.0,
                'all_probs': {
                    'pullup': 0.0,
                    'pushup': 0.0,
                    'unknown': 100.0
                }
            }]
        
        # Преобразуем в массив (каждый кадр - вектор из 34 координат * 2)
        features_list = []
        for frame_id in sorted_frames:
            coords = frame_data[frame_id]
            if len(coords) > 0:
                flat = np.array(coords).flatten()[:68]
                if len(flat) < 68:
                    flat = np.pad(flat, (0, 68 - len(flat)), mode='constant')
                features_list.append(flat)
        
        features = np.array(features_list)
        logger.info(f"📊 Features shape: {features.shape}")
        
        if self.scaler_fitted:
            features = self.scaler.transform(features)
        
        # окна для коротких видео
        seq_length = 30
        stride = 1
        
        if len(features) < seq_length:
            logger.warning(f"Мало кадров ({len(features)}), используем адаптивный seq_length")
            seq_length = max(10, len(features) // 2)
            stride = 1
        
        sequences = []
        for i in range(0, len(features) - seq_length + 1, stride):
            sequences.append(features[i:i + seq_length])
        
        if len(sequences) == 0:
            logger.error("Не удалось создать последовательности")
            return [{
                'exercise': 'unknown',
                'confidence': 100.0,
                'all_probs': {'pullup': 0.0, 'pushup': 0.0, 'unknown': 100.0}
            }]
        
        logger.info(f"Создано {len(sequences)} окон (seq_length={seq_length}, stride={stride})")
        
        # Предсказываем
        predictions = []
        self.model.eval()
        
        with torch.no_grad():
            for seq in sequences:
                X = torch.from_numpy(seq).unsqueeze(0).float().to(self.device)
                output = self.model(X)
                probs = torch.softmax(output, dim=1).cpu().numpy()[0]
                pred_class = np.argmax(probs)
                confidence = probs[pred_class] * 100
                exercise = self.label_encoder.classes_[pred_class]
                
                predictions.append({
                    'exercise': exercise,
                    'confidence': round(confidence, 2),
                    'all_probs': {
                        self.label_encoder.classes_[i]: round(float(probs[i]) * 100, 2)
                        for i in range(len(self.label_encoder.classes_))
                    }
                })
        
        return predictions
    
    def train_on_data(self, X_train, y_train, X_val=None, y_val=None, epochs=50, batch_size=32, lr=0.001):
        logger.info("Начинаю обучение...")
        
        # Инициализируем label encoder
        self.label_encoder.fit(y_train)
        num_classes = len(self.label_encoder.classes_)
        logger.info(f"Классы: {self.label_encoder.classes_}")
        
        # Инициализируем scaler
        self.scaler = StandardScaler()
        X_train_scaled = self.scaler.fit_transform(X_train)
        self.scaler_fitted = True
        
        if X_val is not None:
            X_val_scaled = self.scaler.transform(X_val)
            y_val_encoded = self.label_encoder.transform(y_val)
        
        y_train_encoded = self.label_encoder.transform(y_train)
        
        # Создаем последовательности
        seq_length = 30
        X_train_seq = self.create_sequences(X_train_scaled, seq_length=seq_length)
        y_train_seq = y_train_encoded[seq_length - 1:]  # Выравниваем размеры
        
        if X_val is not None:
            X_val_seq = self.create_sequences(X_val_scaled, seq_length=seq_length)
            y_val_seq = y_val_encoded[seq_length - 1:]
        
        # Инициализируем модель
        self.model = BiLSTMClassifier(
            input_size=68,
            hidden_size=256,
            num_layers=2,
            num_classes=num_classes,
            dropout=0.3
        ).to(self.device)
        
        optimizer = torch.optim.Adam(self.model.parameters(), lr=lr)
        criterion = nn.CrossEntropyLoss()
        
        best_val_loss = float('inf')
        patience_counter = 0
        patience = 10
        
        for epoch in range(epochs):
            # Обучение
            self.model.train()
            total_loss = 0
            
            for i in range(0, len(X_train_seq), batch_size):
                batch_X = X_train_seq[i:i + batch_size]
                batch_y = y_train_seq[i:i + batch_size]
                
                X_tensor = torch.from_numpy(batch_X).float().to(self.device)
                y_tensor = torch.from_numpy(batch_y).long().to(self.device)
                
                optimizer.zero_grad()
                output = self.model(X_tensor)
                loss = criterion(output, y_tensor)
                loss.backward()
                optimizer.step()
                
                total_loss += loss.item()
            
            avg_loss = total_loss / max(len(X_train_seq) // batch_size, 1)
            
            # Валидация
            if X_val is not None:
                self.model.eval()
                with torch.no_grad():
                    val_loss = 0
                    correct = 0
                    total = 0
                    
                    for i in range(0, len(X_val_seq), batch_size):
                        batch_X = X_val_seq[i:i + batch_size]
                        batch_y = y_val_seq[i:i + batch_size]
                        
                        X_tensor = torch.from_numpy(batch_X).float().to(self.device)
                        y_tensor = torch.from_numpy(batch_y).long().to(self.device)
                        
                        output = self.model(X_tensor)
                        loss = criterion(output, y_tensor)
                        val_loss += loss.item()
                        
                        _, pred = torch.max(output, 1)
                        correct += (pred == y_tensor).sum().item()
                        total += y_tensor.size(0)
                    
                    avg_val_loss = val_loss / max(len(X_val_seq) // batch_size, 1)
                    val_acc = 100 * correct / total if total > 0 else 0
                    
                    logger.info(f"Epoch {epoch+1}/{epochs} | Train Loss: {avg_loss:.4f} | Val Loss: {avg_val_loss:.4f} | Val Acc: {val_acc:.2f}%")
                    
                    if avg_val_loss < best_val_loss:
                        best_val_loss = avg_val_loss
                        patience_counter = 0
                    else:
                        patience_counter += 1
                    
                    if patience_counter >= patience:
                        logger.info(f"⏸Early stopping на эпохе {epoch+1}")
                        break
            else:
                logger.info(f"Epoch {epoch+1}/{epochs} | Train Loss: {avg_loss:.4f}")
        
        logger.info("Обучение завершено!")
    
    def save_model(self, model_path, scaler_path=None):
        if self.model is None:
            logger.error("Модель не инициализирована!")
            return
        
        Path(model_path).parent.mkdir(parents=True, exist_ok=True)
        
        checkpoint = {
            'model_state': self.model.state_dict(),
            'classes': self.label_encoder.classes_
        }
        torch.save(checkpoint, model_path)
        logger.info(f"Модель сохранена: {model_path}")
        
        if self.scaler_fitted and scaler_path:
            Path(scaler_path).parent.mkdir(parents=True, exist_ok=True)
            joblib.dump(self.scaler, scaler_path)
            logger.info(f"Scaler сохранен: {scaler_path}")