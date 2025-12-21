import logging
import numpy as np
import cv2
from pathlib import Path
import yaml

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

CONFIG_PATH = Path(__file__).parent.parent / 'config' / 'config.yaml'

with open(CONFIG_PATH) as f:
    config = yaml.safe_load(f)


class SkeletonValidator:
    # валидация скелета для упражнений из config.yaml
    
    def __init__(self):
        with open(CONFIG_PATH) as f:
            self.config = yaml.safe_load(f)
        
        self.pushup_config = self.config.get('pushup', {})
        self.pullup_config = self.config.get('pullup', {})
    
    def calculate_angle(self, point1, point2, point3):
        # Вычисляет угол в градусах между тремя точками
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
    
    def denormalize_keypoints(self, keypoints_norm, center_x, center_y, unit_length, bbox, image_shape):
        # Преобразует нормализованные ключевые точки в пиксельные координаты
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
        # Проверка отжимания
        
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
        # проверка подтягивания
        
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
            issues.append("Недостаточно данных для анализа")
        
        return {
            'issues': issues,
            'metrics': metrics,
            'problems': problems
        }
    
    def validate_exercise(self, exercise_type: str, keypoints: Dict[str, Tuple[int, int]]) -> Dict:
        # общая функция валидации упражнения
        
        if exercise_type.lower() == 'pushup':
            return self.validate_pushup(keypoints)
        elif exercise_type.lower() == 'pullup':
            return self.validate_pullup(keypoints)
        else:
            return {'is_correct': False, 'issues': ['Unknown exercise type'], 'metrics': {}}


# применение использования
if __name__ == "__main__":
    validator = SkeletonValidator()
    
    # Пример скелета отжимания
    pushup_keypoints = {
        'LEFT_SHOULDER': (100, 150),
        'RIGHT_SHOULDER': (300, 150),
        'LEFT_ELBOW': (120, 250),
        'RIGHT_ELBOW': (280, 250),
        'LEFT_WRIST': (140, 350),
        'RIGHT_WRIST': (260, 350),
        'LEFT_HIP': (110, 400),
        'RIGHT_HIP': (290, 400),
    }
    
    print("=" * 70)
    print("проверка PUSHUP")
    print("=" * 70)
    result = validator.validate_pushup(pushup_keypoints)
    print(f"\n{'ПРАВИЛЬНО' if result['is_correct'] else 'НЕПРАВИЛЬНО'}\n")
    for issue in result['issues']:
        print(f"  {issue}")
    print(f"\n Метрики: {result['metrics']}\n")