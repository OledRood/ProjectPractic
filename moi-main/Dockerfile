# Model Training/Inference Dockerfile
# Python 3.9.6 base image для совместимости с backend
FROM python:3.9.6-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Установка системных зависимостей для ML libraries (torch, opencv, mediapipe)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    wget \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    libatlas-base-dev \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Копируем requirements.txt
COPY requirements.txt .

# Обновляем pip и устанавливаем зависимости
# --no-cache-dir для уменьшения размера слоя
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Копируем код модели
COPY . .

# Создаем директории для моделей и результатов если их нет
RUN mkdir -p /app/models /app/results /app/data

# Переменные окружения для Python
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Default command - можно запустить training script или использовать как базу
# Замени на свой скрипт if needed
CMD ["python", "-c", "import torch; print(f'PyTorch version: {torch.__version__}'); print('Model container is ready')"]
