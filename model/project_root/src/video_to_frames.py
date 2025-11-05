import cv2
import os
import argparse
# python video_to_frames.py --video ../data/dataset/video/video1.mp4 --rotate 90/180/270

def video_to_frames(video_path, output_folder, video_name, rotate=None):
    print(f"[INFO] Загружаю видео: {video_path}")
    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        print(f"[ERROR] Не удалось открыть видео: {video_path}")
        return

    os.makedirs(output_folder, exist_ok=True)

    frame_count = 0
    saved_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if rotate == "90":
            frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
        elif rotate == "180":
            frame = cv2.rotate(frame, cv2.ROTATE_180)
        elif rotate == "270":
            frame = cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)

        frame_filename = os.path.join(output_folder, f"frame_{frame_count:05d}.png")
        cv2.imwrite(frame_filename, frame)

        if frame_count % 50 == 0:
            print(f"[INFO] Сохранено кадров: {saved_count}")

        frame_count += 1
        saved_count += 1

    cap.release()
    print(f"[INFO] Всего обработано кадров: {frame_count}")
    print(f"[INFO] Всего сохранено кадров: {saved_count}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Разрезает видео на кадры")
    parser.add_argument("--video", required=True, help="Путь к видео")
    parser.add_argument("--rotate", choices=["90", "180", "270"], help="Повернуть кадры")
    args = parser.parse_args()

    video_path = args.video
    video_name = os.path.splitext(os.path.basename(video_path))[0]
    output_folder = os.path.join("/Users/nikko/Downloads/ProjectPractic-model-2/model/project_root/data/visualizations/video/", video_name)

    video_to_frames(video_path, output_folder, video_name, rotate=args.rotate)