import cv2
import argparse
from pathlib import Path

def merge_frames_to_video(frames_dir: Path, output_video: Path, fps: int = 30):
    frames_dir = frames_dir.resolve()
    if not frames_dir.exists():
        print(f"[ERROR] Папка с кадрами не найдена: {frames_dir}")
        return

    frame_files = sorted(frames_dir.glob("*.png"))
    if not frame_files:
        print(f"[ERROR] Нет PNG кадров в папке: {frames_dir}")
        return

    first_frame = cv2.imread(str(frame_files[0]))
    if first_frame is None:
        print(f"[ERROR] Не удалось прочитать первый кадр: {frame_files[0]}")
        return

    h, w, _ = first_frame.shape
    out = cv2.VideoWriter(
        str(output_video),
        cv2.VideoWriter_fourcc(*'mp4v'),
        fps,
        (w, h)
    )

    print(f"[INFO] Создание видео {output_video} из {len(frame_files)} кадров...")

    for idx, f in enumerate(frame_files):
        frame = cv2.imread(str(f))
        if frame is None:
            print(f"[WARN] Не удалось прочитать кадр: {f}")
            continue
        out.write(frame)
        if idx % 50 == 0 or idx == len(frame_files)-1:
            print(f"[INFO] Добавлено {idx+1}/{len(frame_files)} кадров")

    out.release()
    print(f"[DONE] Видео сохранено: {output_video}")

def main():
    parser = argparse.ArgumentParser(description="Склеивание PNG кадров в видео")
    parser.add_argument("--frames_dir", required=True, help="Папка с PNG кадрами")
    parser.add_argument("--output", required=True, help="Выходной файл видео (.mp4)")
    parser.add_argument("--fps", type=int, default=30, help="FPS для выходного видео")
    args = parser.parse_args()

    frames_dir = Path(args.frames_dir)
    output_video = Path(args.output)
    merge_frames_to_video(frames_dir, output_video, fps=args.fps)

if __name__ == "__main__":
    main()

# python merge_frames_to_video.py --frames_dir ../data/visualizations/video/video1 --output ../data/visualizations/video/video1.mp4 --fps 30