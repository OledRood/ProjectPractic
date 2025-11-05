import os
import subprocess
from pathlib import Path
from typing import Dict, Tuple, Optional
from exercise_recognition_model import infer_exercise

def get_exercise_prediction(csv_path: str) -> Tuple[str, str]:
    """
    Получает предсказание типа упражнения и его корректности из CSV файла с данными поз.
    
    Args:
        csv_path (str): Путь к CSV файлу с данными поз
        
    Returns:
        Tuple[str, str]: (тип_упражнения, корректность)
        Например: ("long_jump", "correct") или ("pushup", "incorrect")
    """
    predictions = infer_exercise(csv_path)
    if predictions:
        return predictions[0]['exercise_type'], predictions[0]['correctness']
    return "unknown", "unknown"

def process_video_with_rotation(video_path: str, rotation_angle: Optional[int] = None) -> str:
    """
    Обрабатывает видео с возможностью поворота и разделяет его на кадры.
    
    Args:
        video_path (str): Путь к видеофайлу
        rotation_angle (int, optional): Угол поворота (90, 180, 270 или None)
        
    Returns:
        str: Путь к папке с извлеченными кадрами
    """
    if rotation_angle and rotation_angle not in [90, 180, 270]:
        raise ValueError("Угол поворота должен быть 90, 180 или 270 градусов")
        
    video_name = Path(video_path).stem
    project_root = Path(__file__).parent.parent
    frames_dir = project_root / 'data' / 'visualizations' / 'video' / video_name
    
    cmd = ["python", "video_to_frames.py", "--video", video_path]
    if rotation_angle:
        cmd.extend(["--rotate", str(rotation_angle)])
        
    # Запускаем process_video из текущей директории
    subprocess.run(cmd, check=True, cwd=str(Path(__file__).parent))
    
    return str(frames_dir)

def analyze_video_frames(frames_dir: str, fps: int = 60) -> Dict[str, str]:
    """
    Анализирует кадры видео, визуализирует позы и создает итоговое видео.
    
    Args:
        frames_dir (str): Путь к папке с кадрами
        fps (int): Кадров в секунду для выходного видео
        
    Returns:
        Dict[str, str]: Словарь с результатами:
            - 'exercise_type': тип упражнения
            - 'correctness': корректность выполнения
            - 'output_video': путь к выходному видео
    """
    project_root = Path(__file__).parent.parent
    video_name = Path(frames_dir).name
    
    cmd = [
        "python",
        "fitness_pipeline_manager.py",
        "--frames_dir", frames_dir,
        "--process",
        "--visualize",
        "--assemble",
        "--fps", str(fps)
    ]
    
    # Запускаем pipeline manager из текущей директории
    subprocess.run(cmd, check=True, cwd=str(Path(__file__).parent))
    
    # Получаем результаты анализа
    csv_path = project_root / 'data' / 'annotations' / f'{video_name}_pose_data.csv'
    exercise_type, correctness = get_exercise_prediction(str(csv_path))
    
    # Путь к выходному видео (создается pipeline manager'ом)
    output_video = project_root / 'data' / 'visualizations' / 'video' / f'{video_name}_analyzed.mp4'
    
    return {
        'exercise_type': exercise_type,
        'correctness': correctness,
        'output_video': str(output_video)
    }

# Пример использования:
if __name__ == "__main__":
    # Пример обработки видео с поворотом
    video_path = "../data/dataset/video/video1.mp4"
    frames_dir = process_video_with_rotation(video_path, rotation_angle=90)
    
    # Анализ кадров и получение результатов
    results = analyze_video_frames(frames_dir)
    print(f"Тип упражнения: {results['exercise_type']}")
    print(f"Корректность: {results['correctness']}")
    print(f"Выходное видео: {results['output_video']}")