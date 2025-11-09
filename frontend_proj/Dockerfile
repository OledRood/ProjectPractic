# Этап 1: Сборка Flutter web приложения
FROM debian:latest AS build-env

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Установка Flutter SDK
ARG FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter -b stable
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Включение Flutter web
RUN flutter config --enable-web
RUN flutter doctor

# Копирование проекта
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get

COPY . .

# Сборка web приложения
RUN flutter build web --release

# Этап 2: Nginx для раздачи статики
FROM nginx:alpine

# Копирование собранного приложения
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Копирование конфигурации nginx (опционально)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Открытие порта
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
