# Backend FastAPI + Model Integration Dockerfile
# Python 3.9.6 slim base image для меньшего размера контейнера
FROM python:3.9.6-slim

# Установка рабочей директории
WORKDIR /app

# Установка системных зависимостей для компиляции Python пакетов
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libopenblas-dev \
    liblapack-dev \
    gfortran \
    libatlas-base-dev \
    && rm -rf /var/lib/apt/lists/*

# Копирование requirements.txt
COPY requirements.txt .

# Установка Python зависимостей
# --no-cache-dir для уменьшения размера слоя
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Копирование кода приложения
COPY . .

# Expose порт для FastAPI сервера (меняй если нужно другой)
EXPOSE 8000

# Health check для Docker Compose / Kubernetes
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Запуск приложения с uvicorn
# --host 0.0.0.0 позволяет слушать на всех интерфейсах
# --port 8000 порт сервера
# Для production рекомендуется использовать gunicorn + uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
