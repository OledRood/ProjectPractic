# Этап 1: Сборка Flutter web приложения
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build-env

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
