# Frontend Flutter Web Dockerfile
# Multi-stage build для оптимизации размера контейнера

# Этап 1: Сборка Flutter web приложения
FROM debian:latest AS build-env

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Установка Flutter SDK (stable версия)
ARG FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Включение Flutter web
RUN flutter config --enable-web
RUN flutter doctor

# Копирование файлов проекта (только pubspec для кэширования)
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

# Копирование оставшихся файлов проекта
COPY . .

# Сборка web приложения в release mode
RUN flutter build web --release

# Этап 2: Production stage с nginx для раздачи статики
FROM nginx:alpine

# Установка curl для healthcheck
RUN apk add --no-cache curl

# Копирование собранного приложения из build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Копирование конфигурации nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Открытие порта для веб-трафика
EXPOSE 80

# Health check для Docker/Kubernetes
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/index.html || exit 1

# Запуск nginx
CMD ["nginx", "-g", "daemon off;"]
