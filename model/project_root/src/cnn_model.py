import os
import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader, random_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report
import numpy as np
from tqdm import tqdm

class PoseDataset(Dataset):
    def __init__(self, csv_paths):
        self.data = []
        self.labels = []
        self.encoder = LabelEncoder()
        
        self.expected_landmarks = [
            'LEFT_SHOULDER', 'RIGHT_SHOULDER',
            'LEFT_ELBOW', 'RIGHT_ELBOW',
            'LEFT_WRIST', 'RIGHT_WRIST',
            'LEFT_HIP', 'RIGHT_HIP',
            'LEFT_KNEE', 'RIGHT_KNEE',
            'LEFT_ANKLE', 'RIGHT_ANKLE',
            'LEFT_EYE', 'RIGHT_EYE'
        ]
        
        for csv_path in csv_paths:
            df = pd.read_csv(csv_path)
            class_name = os.path.basename(os.path.dirname(csv_path))
            
            grouped = df.groupby('image_path')
            for img_path, group in grouped:
                # Initialize all landmarks with zeros
                keypoints = {landmark: [0.0, 0.0] for landmark in self.expected_landmarks}
                
                # Fill available landmarks
                for _, row in group.iterrows():
                    if row['landmark'] in self.expected_landmarks:
                        keypoints[row['landmark']] = [row['x_norm'], row['y_norm']]
                
                # Create feature vector in consistent order
                features = []
                for landmark in self.expected_landmarks:
                    features.extend(keypoints[landmark])
                
                self.data.append(features)
                self.labels.append(class_name)
        
        self.labels = self.encoder.fit_transform(self.labels)
    
    def __len__(self):
        return len(self.data)
    
    def __getitem__(self, idx):
        features = torch.FloatTensor(self.data[idx])
        label = torch.LongTensor([self.labels[idx]])
        return features, label.squeeze()

class PoseCNN(nn.Module):
    def __init__(self, input_size, num_classes):
        super(PoseCNN, self).__init__()
        self.fc = nn.Sequential(
            nn.Linear(input_size, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 128),
            nn.ReLU(),
            nn.Linear(128, num_classes)
        )
    
    def forward(self, x):
        return self.fc(x)

def train_pose_classifier(
    csv_paths,
    model_save_path='models/pose_classifier.pth',
    epochs=30,
    batch_size=32,
    learning_rate=0.001
):
    """Train pose classification model"""
    # Create dataset
    dataset = PoseDataset(csv_paths)
    
    # Split dataset
    train_size = int(0.8 * len(dataset))
    test_size = len(dataset) - train_size
    train_dataset, test_dataset = random_split(dataset, [train_size, test_size])
    
    # Create data loaders
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
    
    # Initialize model
    input_size = len(dataset[0][0])
    num_classes = len(dataset.encoder.classes_)
    model = PoseCNN(input_size, num_classes)
    
    # Training setup
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    
    # Training loop
    for epoch in range(epochs):
        model.train()
        total_loss = 0
        for features, labels in tqdm(train_loader, desc=f"Epoch {epoch+1}/{epochs}"):
            optimizer.zero_grad()
            outputs = model(features)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        
        # Validation
        model.eval()
        correct = 0
        total = 0
        all_preds = []
        all_labels = []
        
        with torch.no_grad():
            for features, labels in test_loader:
                outputs = model(features)
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()
                all_preds.extend(predicted.cpu().numpy())
                all_labels.extend(labels.cpu().numpy())
        
        # Print classification report every 5 epochs
        if (epoch + 1) % 5 == 0 or epoch == epochs - 1:
            print(f"\nEpoch {epoch+1}/{epochs} Classification Report:")
            print(classification_report(
                all_labels, all_preds,
                target_names=dataset.encoder.classes_
            ))
        
        print(f'Epoch {epoch+1}/{epochs}, Loss: {total_loss/len(train_loader):.4f}, '
              f'Accuracy: {100 * correct / total:.2f}%')
    
    # Save model
    os.makedirs(os.path.dirname(model_save_path), exist_ok=True)
    torch.save({
        'model_state_dict': model.state_dict(),
        'encoder_classes': dataset.encoder.classes_,
        'expected_landmarks': dataset.expected_landmarks,
        'input_size': input_size,
        'num_classes': num_classes
    }, model_save_path)
    
    print(f"Model saved to {model_save_path}")
    return model

if __name__ == "__main__":
    csv_paths = [
        "data/standing/annotations.csv",
        "data/sitting/annotations.csv",
        "data/lying/annotations.csv"
    ]
    train_pose_classifier(csv_paths)