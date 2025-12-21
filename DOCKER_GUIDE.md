# Docker Setup Guide для ProjectPractic

## 📋 Описание структуры

Проект разбит на три отдельных Docker контейнера:

1. **Backend** (`backend/Dockerfile`) - FastAPI сервер (Python 3.9.6)
2. **Model** (`moi-main/Dockerfile`) - ML модель для обработки (Python 3.9.6)
3. **Frontend** (`frontend_proj/Dockerfile`) - Flutter Web приложение (Nginx)

## 🚀 Быстрый старт

### Требования
- Docker и Docker Compose установлены
- ~15-20 GB свободного места (особенно для torch/ultralytics моделей)
- Git

### Запуск всего стека

```bash
# Клонируем репозиторий
git clone https://github.com/OledRood/ProjectPractic.git
cd ProjectPractic

# Запускаем все контейнеры
docker-compose up --build
```

**Что будет запущено:**
- Backend: http://localhost:8000
- Frontend: http://localhost:80 (или http://localhost)
- Model: Internal service (используется backend'ом)

## 🔧 Отдельный запуск контейнеров

### Backend

```bash
# Сборка
docker build -t projectpractice-backend ./backend

# Запуск
docker run -p 8000:8000 \
  -v $(pwd)/backend:/app \
  --name backend \
  projectpractice-backend

# С reload (для development)
# uvicorn уже настроен на reload в Dockerfile
```

### Model

```bash
# Сборка (долгий процесс - загружаются PyTorch и другие ML библиотеки)
docker build -t projectpractice-model ./moi-main

# Запуск (interactive mode)
docker run -it \
  -v $(pwd)/moi-main:/app \
  -v projectpractice_model_data:/app/models \
  --name model \
  projectpractice-model /bin/bash
```

### Frontend

```bash
# Сборка (тоже долгая - компилирует Flutter)
docker build -t projectpractice-frontend ./frontend_proj

# Запуск
docker run -p 80:80 \
  --name frontend \
  projectpractice-frontend
```

## 💾 Оптимизация для быстрой загрузки

### Проблема: Долгая загрузка библиотек

Первая сборка может занять **10-30 минут**:
- PyTorch (~2 GB)
- OpenCV, ultralytics, mediapipe
- Flutter SDK

### Решение

1. **Используйте Docker BuildKit** (быстрее кэшируется):
   ```bash
   docker buildx build -t projectpractice-backend ./backend
   ```

2. **Pre-cache слои**:
   ```bash
   # Сначала соберём только зависимости
   docker build -t projectpractice-backend:base ./backend
   ```

3. **Используйте volume mounting** в development:
   ```bash
   docker-compose up -d
   # Волюмы кэшируют установленные пакеты
   ```

## 🐳 Docker Compose команды

```bash
# Запуск всех сервисов в фоне
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Логи отдельного сервиса
docker-compose logs -f backend
docker-compose logs -f model
docker-compose logs -f frontend

# Остановка
docker-compose down

# Полная очистка (удалит волюмы)
docker-compose down -v

# Пересборка конкретного сервиса
docker-compose up -d --build backend

# Запуск команды в контейнере
docker-compose exec backend python -m pytest
docker-compose exec model python train.py
```

## 📝 Environment переменные

### Backend

Добавьте в `docker-compose.yml` в секцию `backend -> environment`:

```yaml
environment:
  - DATABASE_URL=postgresql://user:password@db:5432/projectpractice
  - MODEL_SERVICE_URL=http://model:8000
  - LOG_LEVEL=info
```

### Model

```yaml
environment:
  - BATCH_SIZE=32
  - GPU_MEMORY_FRACTION=0.8
```

## ⚠️ Частые проблемы и решения

### 1. "Пакеты загружаются слишком долго"

**Причина**: Первая загрузка PyTorch (~2 GB)

**Решение**:
```bash
# Используйте Docker с более агрессивным параллелизмом
export DOCKER_BUILDKIT=1
docker-compose build --parallel
```

### 2. "OutOfMemory при сборке"

**Решение**: Увеличьте memory в Docker Desktop:
- Docker Desktop Settings → Resources → Memory → 8GB+ (рекомендуется 12GB)

### 3. "Модель контейнер не запускается"

```bash
# Проверьте логи
docker logs projectpractice-model

# Если проблема с PyTorch, проверьте CUDA compatibility
docker-compose exec model python -c "import torch; print(torch.cuda.is_available())"
```

### 4. "Backend не может подключиться к Model"

**Причина**: Сервис model не запущен или не готов

**Решение**:
```bash
# Проверьте health status
docker-compose ps

# Убедитесь что model запущен
docker-compose logs model
```

## 🔍 Проверка работоспособности

```bash
# Backend
curl http://localhost:8000/health

# Frontend
curl http://localhost/

# Docker health checks
docker ps
# Статус HEALTHY/UNHEALTHY показывается в STATUS колонке
```

## 🛠️ Development workflow

### 1. Запустите стек
```bash
docker-compose up -d
```

### 2. При изменении code (backend)
```bash
# uvicorn автоматически перезагрузит при --reload флаге
# Просто сохраните файл - изменения применятся
```

### 3. При изменении dependencies

**Backend:**
```bash
docker-compose up -d --build backend
```

**Model:**
```bash
docker-compose up -d --build model
```

## 📊 Performance tips

1. **Используйте volume mounting для development**:
   ```yaml
   volumes:
     - ./backend:/app  # Hot reload
   ```

2. **Закэшируйте layers при production сборке**:
   ```bash
   docker build --cache-from projectpractice-backend:latest .
   ```

3. **Используйте .dockerignore** (уже добавлено):
   - Исключает `__pycache__`, `.git`, logs
   - Уменьшает build context size

## 🚀 Deployment (Примеры)

### На VPS с Docker

```bash
# SSH на сервер
ssh user@vps-ip

# Клонируем репо
git clone https://github.com/OledRood/ProjectPractic.git
cd ProjectPractic

# Запускаем
docker-compose -f docker-compose.yml up -d
```

### Для Kubernetes

Потребуются дополнительные файлы:
- `k8s/backend-deployment.yaml`
- `k8s/model-deployment.yaml`
- `k8s/frontend-deployment.yaml`
- `k8s/service.yaml`

## 📚 Полезные ссылки

- [Docker Compose docs](https://docs.docker.com/compose/)
- [Python Docker best practices](https://docs.docker.com/language/python/)
- [Flutter Docker](https://docs.flutter.dev/deployment/cd#building-for-web)

## 🤝 FAQ

**Q: Могу ли я использовать Docker на Windows?**
A: Да, используйте Docker Desktop for Windows. При проблемах с путями используйте `${pwd}` (PowerShell) или `%cd%` (CMD).

**Q: Как отлаживать Python code в контейнере?**
A: Используйте `docker exec -it backend python -m pdb` или IDE с remote debugging.

**Q: Где хранятся модели?**
A: В Docker volume `projectpractice_model_data` и `projectpractice_model_cache`.

Удалить:
```bash
docker volume rm projectpractice_model_data projectpractice_model_cache
```

---

**Все готово! 🎉**

При возникновении вопросов - проверьте логи:
```bash
docker-compose logs -f
```
