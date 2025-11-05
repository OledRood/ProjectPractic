from backend_interface import process_video_with_rotation, analyze_video_frames

def test_video_processing():
    # Путь к тестовому видео (используем существующее видео из вашего набора данных)
    video_path = "/Users/nikko/Downloads/ProjectPractic-model-2/model/project_root/data/dataset/video/push_up.mp4"
    
    try:
        # Шаг 1: Проверяем обработку видео с поворотом
        print("Шаг 1: Обработка видео...")
        frames_dir = process_video_with_rotation(video_path, rotation_angle=None)
        print(f"✓ Кадры сохранены в: {frames_dir}")
        
        # Шаг 2: Анализируем кадры
        print("\nШаг 2: Анализ кадров...")
        results = analyze_video_frames(frames_dir, fps=60)
        
        # Шаг 3: Выводим результаты
        print("\nРезультаты анализа:")
        print(f"✓ Тип упражнения: {results['exercise_type']}")
        print(f"✓ Корректность: {results['correctness']}")
        print(f"✓ Выходное видео: {results['output_video']}")
        
    except Exception as e:
        print(f"\n❌ Ошибка: {str(e)}")
        raise

if __name__ == "__main__":
    print("Начинаем тестирование backend_interface...")
    print("-" * 50)
    test_video_processing()
    print("-" * 50)
    print("Тестирование завершено!")