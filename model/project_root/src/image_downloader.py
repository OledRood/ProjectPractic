from bing_image_downloader import downloader
from PIL import Image, ImageEnhance, ImageOps
import imagehash
import os
import shutil
import random

# Константы
MIN_SIZE = (300, 300)
DOWNLOAD_LIMIT = 100
TARGET_COUNT = 300
CLASSES = {
    "standing": "person standing full body",
    "sitting": "person sitting full body",
    "lying": "person lying down full body"
}

# Пути
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATASET_DIR = os.path.join(PROJECT_ROOT, "project_root", "data", "dataset")
PREVIEW_HTML = os.path.join(PROJECT_ROOT, "project_root", "data", "preview.html")

def download_images():
    """Скачивает изображения и правильно их распределяет"""
    for class_name, query in CLASSES.items():
        class_dir = os.path.join(DATASET_DIR, class_name)
        temp_dir = os.path.join(DATASET_DIR, f"temp_{class_name}")
        
        # Создаем временную папку для загрузки
        os.makedirs(temp_dir, exist_ok=True)
        
        print(f"[🔽] Downloading images for '{class_name}'...")
        downloader.download(
            query,
            limit=DOWNLOAD_LIMIT,
            output_dir=temp_dir,
            adult_filter_off=True,
            force_replace=True,
            timeout=60,
            verbose=True
        )

        # Переносим файлы из временной папки в целевую
        downloaded_dir = os.path.join(temp_dir, query)
        if os.path.exists(downloaded_dir):
            os.makedirs(class_dir, exist_ok=True)
            for img in os.listdir(downloaded_dir):
                src = os.path.join(downloaded_dir, img)
                dst = os.path.join(class_dir, img)
                try:
                    shutil.move(src, dst)
                except Exception as e:
                    print(f"[⚠️] Failed to move {src}: {e}")
            
            # Удаляем временные папки
            shutil.rmtree(temp_dir)

def clean_images():
    """Очищает и конвертирует изображения"""
    print("[🧹] Cleaning images...")
    for class_name in CLASSES:
        class_dir = os.path.join(DATASET_DIR, class_name)
        if not os.path.exists(class_dir):
            print(f"[⚠️] Папка {class_dir} не найдена, пропускаем.")
            continue

        hashes = set()
        for img_name in os.listdir(class_dir):
            img_path = os.path.join(class_dir, img_name)
            
            # Пропускаем папки (на случай, если что-то осталось)
            if os.path.isdir(img_path):
                continue
                
            try:
                with Image.open(img_path) as img:
                    # Проверка размера
                    if img.size[0] < MIN_SIZE[0] or img.size[1] < MIN_SIZE[1]:
                        os.remove(img_path)
                        continue

                    # Проверка дубликатов
                    img_hash = imagehash.average_hash(img)
                    if img_hash in hashes:
                        os.remove(img_path)
                        continue
                    hashes.add(img_hash)

                    # Конвертация в JPG
                    if not img_name.lower().endswith('.jpg'):
                        new_name = f"{os.path.splitext(img_name)[0]}.jpg"
                        new_path = os.path.join(class_dir, new_name)
                        img.convert('RGB').save(new_path, 'JPEG', quality=90)
                        os.remove(img_path)

            except Exception as e:
                print(f"[⚠️] Ошибка обработки {img_path}: {e}")
                try:
                    os.remove(img_path)
                except:
                    pass

def augment_dataset():
    """Аугментирует изображения"""
    print("[🔁] Augmenting images...")
    for class_name in CLASSES:
        class_dir = os.path.join(DATASET_DIR, class_name)
        if not os.path.exists(class_dir):
            print(f"[⚠️] Папка {class_dir} не найдена, пропускаем.")
            continue

        images = [f for f in os.listdir(class_dir) if f.lower().endswith('.jpg')]
        if len(images) == 0:
            print(f"[⚠️] Нет изображений в {class_dir}, пропускаем.")
            continue

        index = len(images)
        while len(images) < TARGET_COUNT and index < TARGET_COUNT * 2:
            img_name = random.choice(images)
            img_path = os.path.join(class_dir, img_name)
            
            try:
                with Image.open(img_path) as img:
                    # Аугментации
                    transformations = [
                        img.rotate(90),
                        img.rotate(180),
                        img.rotate(270),
                        ImageOps.mirror(img),
                        ImageEnhance.Brightness(img).enhance(random.uniform(0.7, 1.3)),
                        ImageEnhance.Contrast(img).enhance(random.uniform(0.7, 1.3))
                    ]
                    
                    for aug_img in transformations:
                        if len(images) >= TARGET_COUNT:
                            break
                            
                        aug_name = f"aug_{index}.jpg"
                        aug_path = os.path.join(class_dir, aug_name)
                        aug_img.save(aug_path)
                        images.append(aug_name)
                        index += 1
                        
            except Exception as e:
                print(f"[⚠️] Ошибка аугментации {img_path}: {e}")

def create_preview():
    """Создает HTML-превью"""
    print("[🖼] Creating preview HTML...")
    os.makedirs(os.path.dirname(PREVIEW_HTML), exist_ok=True)
    
    with open(PREVIEW_HTML, 'w', encoding='utf-8') as f:
        f.write('''<html>
<head>
    <title>Dataset Preview</title>
    <style>
        .class-container { margin-bottom: 30px; }
        .image-grid { display: flex; flex-wrap: wrap; gap: 10px; }
        .image-item { border: 1px solid #ddd; padding: 5px; }
    </style>
</head>
<body>
    <h1>Dataset Preview</h1>''')

        for class_name in CLASSES:
            class_dir = os.path.join(DATASET_DIR, class_name)
            if not os.path.exists(class_dir):
                continue

            f.write(f'<div class="class-container"><h2>{class_name.capitalize()}</h2><div class="image-grid">')
            
            images = [f for f in os.listdir(class_dir) if f.lower().endswith('.jpg')][:15]
            for img in images:
                rel_path = os.path.join('dataset', class_name, img).replace('\\', '/')
                f.write(f'''<div class="image-item">
                    <img src="{rel_path}" height="150">
                    <div>{img}</div>
                </div>''')
            
            f.write('</div></div>')
        
        f.write('</body></html>')
    
    print(f"[✅] Preview saved to: {PREVIEW_HTML}")

if __name__ == "__main__":
    # Проверка путей
    print(f"[DEBUG] PROJECT_ROOT: {PROJECT_ROOT}")
    print(f"[DEBUG] DATASET_DIR: {DATASET_DIR}")
    
    download_images()
    clean_images()
    augment_dataset()
    create_preview()