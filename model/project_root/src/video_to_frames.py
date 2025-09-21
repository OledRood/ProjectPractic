import cv2
import os
import argparse

def video_to_frames(video_path, output_dir):
    print(f"[INFO] Загружаю видео: {os.path.abspath(video_path)}")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"[ERROR] Не удалось открыть видео: {video_path}")
        return

    video_name = os.path.splitext(os.path.basename(video_path))[0]
    output_path = os.path.join(output_dir, video_name)

    os.makedirs(output_path, exist_ok=True)
    print(f"[INFO] Папка для кадров: {os.path.abspath(output_path)}")

    frame_count = 0
    saved_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_file = os.path.join(output_path, f"frame_{frame_count:05d}.png")
        success = cv2.imwrite(frame_file, frame)
        if success:
            saved_count += 1
        else:
            print(f"[WARNING] Ошибка сохранения кадра {frame_file}")

        if frame_count % 10 == 0:  # каждые 10 кадров лог
            print(f"[INFO] Обработано {frame_count} кадров, сохранено {saved_count}")

        frame_count += 1

    cap.release()
    print(f"[INFO] Всего обработано кадров: {frame_count}")
    print(f"[INFO] Всего сохранено кадров: {saved_count}")
    print(f"[INFO] Кадры лежат в: {os.path.abspath(output_path)}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", required=True, help="Путь к видеофайлу")
    parser.add_argument("--output", default="../data/visualizations/video", help="Папка для сохранения кадров")
    args = parser.parse_args()

    video_to_frames(args.video, args.output)