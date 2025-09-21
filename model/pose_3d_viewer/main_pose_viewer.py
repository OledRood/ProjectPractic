import cv2
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import csv
from pathlib import Path
from collections import defaultdict
import argparse
import json

def load_config(config_path="config/viewer_config.json"):
    """Загрузка конфигурации из JSON."""
    try:
        with open(Path(__file__).parent / config_path) as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Конфиг {config_path} не найден")
        return {}
    except Exception as e:
        print(f"Ошибка чтения конфига: {e}")
        return {}

def load_connections(conn_path="config/skeleton_connections.json"):
    """Загрузка связей между суставами из JSON."""
    try:
        with open(Path(__file__).parent / conn_path) as f:
            return json.load(f)["connections"]
    except FileNotFoundError:
        print(f"Файл связей {conn_path} не найден")
        return []
    except Exception as e:
        print(f"Ошибка чтения связей: {e}")
        return []

def load_keypoints(csv_path):
    """Чтение ключевых точек из CSV с новым форматом."""
    data = defaultdict(list)
    try:
        with open(csv_path, 'r', newline='', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            expected_fields = ['image_path', 'bbox', 'landmark', 'x_norm', 'y_norm', 'visibility', 'class', 'center_x', 'center_y', 'unit_length']
            if not all(field in reader.fieldnames for field in expected_fields):
                print(f"Предупреждение: Ожидаемые поля {expected_fields} не совпадают с заголовками файла.")
                return {}
            for row in reader:
                img_path = row['image_path'].replace('\\', '/')
                data[img_path].append({
                    'landmark': row['landmark'],
                    'x_norm': float(row['x_norm']),
                    'y_norm': float(row['y_norm']),
                    'z_norm': float(row['visibility']),  # Используем visibility как z_norm
                    'visibility': 1.0,  # Устанавливаем фиктивное значение видимости, так как оно не предоставлено
                    'pose_class': row['class'],
                    'bbox': eval(row['bbox'])
                })
        return data
    except FileNotFoundError:
        print(f"CSV файл не найден: {csv_path}")
        return {}
    except Exception as e:
        print(f"Ошибка чтения CSV: {e}")
        return {}

def denormalize_keypoints(keypoints, bbox, image_shape):
    """Де-нормализация координат ключевых точек с учетом bounding box."""
    height, width = image_shape[:2]
    x1, y1, x2, y2 = bbox
    bbox_width = x2 - x1
    bbox_height = y2 - y1
    keypoints_scaled = {}
    
    for kp in keypoints:
        try:
            x = x1 + kp['x_norm'] * bbox_width
            y = y1 + kp['y_norm'] * bbox_height
            z = kp['z_norm']
            keypoints_scaled[kp['landmark']] = (x, y, z)
        except (KeyError, ValueError) as e:
            print(f"Ошибка обработки точки {kp.get('landmark', 'unknown')}: {e}")
            continue
    return keypoints_scaled

def draw_2d_skeleton(image, keypoints, pose_class, bbox, config, connections):
    """Отрисовка 2D скелета на изображении."""
    overlay = image.copy() if image is not None else np.ones((*config['image_size'][::-1], 3), dtype=np.uint8) * 255
    
    highlight_color = config['poses'].get(pose_class, {}).get('highlight_color', config['colors']['torso'])
    
    for start, end in connections:
        if start in keypoints and end in keypoints:
            color = config['colors']['torso']
            if any(k in start for k in ['EYE', 'NOSE', 'MOUTH', 'EAR']):
                color = config['colors']['face']
            elif any(k in start for k in ['SHOULDER', 'ELBOW', 'WRIST']):
                color = config['colors']['arms']
            elif any(k in start for k in ['HIP', 'KNEE', 'ANKLE']):
                color = config['colors']['legs']
            start_point = (int(keypoints[start][0]), int(keypoints[start][1]))
            end_point = (int(keypoints[end][0]), int(keypoints[end][1]))
            cv2.line(overlay, start_point, end_point, color, config['line_thickness'])
    
    for name, (x, y, _) in keypoints.items():
        cv2.circle(overlay, (int(x), int(y)), config['joint_radius'], (0, 0, 0), -1)
        cv2.putText(overlay, name, (int(x) + 10, int(y)), 
                   cv2.FONT_HERSHEY_SIMPLEX, config['font_scale'], (0, 0, 0), 1)
    
    if pose_class:
        cv2.putText(overlay, pose_class.upper(), (30, 50), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, highlight_color, 2)
    
    return overlay

def draw_3d_skeleton(keypoints, pose_class, config, connections):
    """Отрисовка 3D скелета."""
    fig = plt.figure(figsize=config['figure_size'])
    ax = fig.add_subplot(111, projection='3d')
    
    try:
        z_scale = config['poses'].get(pose_class, {}).get('z_scale', 1.0)
        scaled_keypoints = {k: (x, y, z * z_scale) for k, (x, y, z) in keypoints.items()}
        
        all_coords = np.array(list(scaled_keypoints.values()))
        max_range = np.max(all_coords.max(axis=0) - all_coords.min(axis=0)) * 0.6
        mid_x, mid_y, mid_z = np.mean(all_coords, axis=0)
        
        ax.set_xlim(mid_x - max_range, mid_x + max_range)
        ax.set_ylim(mid_y - max_range, mid_y + max_range)
        ax.set_zlim(mid_z - max_range, mid_z + max_range)
        
        for start, end in connections:
            if start in scaled_keypoints and end in scaled_keypoints:
                color = config['colors']['torso']
                if any(k in start for k in ['EYE', 'NOSE', 'MOUTH', 'EAR']):
                    color = config['colors']['face']
                elif any(k in start for k in ['SHOULDER', 'ELBOW', 'WRIST']):
                    color = config['colors']['arms']
                elif any(k in start for k in ['HIP', 'KNEE', 'ANKLE']):
                    color = config['colors']['legs']
                x = [scaled_keypoints[start][0], scaled_keypoints[end][0]]
                y = [scaled_keypoints[start][1], scaled_keypoints[end][1]]
                z = [scaled_keypoints[start][2], scaled_keypoints[end][2]]
                ax.plot(x, y, z, color=np.array(color)/255.0, linewidth=3)
        
        for name, (x, y, z) in scaled_keypoints.items():
            ax.scatter([x], [y], [z], c='black', s=50)
            ax.text(x, y, z, name, size=8)
        
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_zlabel('Z')
        plt.title(f"3D Поза: {pose_class or 'Unknown'}")
        plt.tight_layout()
        plt.show()
        
    except Exception as e:
        print(f"Ошибка 3D визуализации: {e}")
    finally:
        plt.close(fig)

def visualize(csv_path, target_img=None, pose_class=None, clean_canvas=False):
    """Основная функция визуализации."""
    config = load_config()
    connections = load_connections()
    if not config or not connections:
        print("Не удалось загрузить конфигурации, завершение")
        return

    data = load_keypoints(csv_path)
    if not data:
        print("Нет данных для визуализации")
        return

    if pose_class:
        data = {k: v for k, v in data.items() if any(kp['pose_class'].lower() == pose_class.lower() for kp in v)}

    img_path = target_img if target_img else next(iter(data), None)
    if not img_path or img_path not in data:
        print(f"Изображение {img_path} не найдено в данных")
        return

    image = None if clean_canvas else cv2.imread(img_path)
    if image is None and not clean_canvas:
        print(f"Не удалось загрузить изображение {img_path}, используется чистый холст")
        clean_canvas = True

    keypoints_data = data[img_path]
    keypoints_scaled = denormalize_keypoints(keypoints_data, keypoints_data[0]['bbox'], 
                                           config['image_size'] if clean_canvas else image.shape)
    pose = keypoints_data[0]['pose_class']

    print(f"Визуализация: {img_path} | Поза: {pose}")
    
    img_2d = draw_2d_skeleton(image, keypoints_scaled, pose, keypoints_data[0]['bbox'], config, connections)
    if img_2d is not None:
        cv2.imshow("2D Поза", img_2d)
        cv2.waitKey(3000)
        cv2.destroyAllWindows()
    
    draw_3d_skeleton(keypoints_scaled, pose, config, connections)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Визуализация 2D и 3D скелета")
    parser.add_argument('--csv', required=True, help='Путь к CSV с аннотациями')
    parser.add_argument('--image', help='Путь к целевому изображению')
    parser.add_argument('--pose', help='Фильтр по классу позы')
    parser.add_argument('--clean_canvas', action='store_true', help='Использовать чистый холст')
    args = parser.parse_args()

    visualize(args.csv, args.image, args.pose, args.clean_canvas)