#!/bin/bash

# ===========================================
# Скрипт запуска проекта для macOS
# ===========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}    Запуск проекта в Docker${NC}"
echo -e "${CYAN}========================================${NC}"

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker не установлен!${NC}"
    echo "Установите Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Проверка что Docker запущен
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker не запущен!${NC}"
    echo "Запустите Docker Desktop и попробуйте снова."
    exit 1
fi

echo -e "${GREEN}✅ Docker доступен${NC}"

# Переход в директорию проекта
cd "$(dirname "$0")"

# Меню выбора режима
echo ""
echo -e "${YELLOW}Выберите режим запуска:${NC}"
echo "1) Запустить всё (backend + frontend) - РЕКОМЕНДУЕТСЯ"
echo "2) Только backend (без frontend)"
echo "3) Пересобрать и запустить (--build)"
echo "4) Остановить все контейнеры"
echo "5) Посмотреть логи"
echo "6) Статус контейнеров"
echo ""
read -p "Ваш выбор [1-6]: " choice

case $choice in
    1)
        echo -e "${CYAN}🚀 Запуск всех сервисов...${NC}"
        docker-compose up -d
        echo ""
        echo -e "${GREEN}✅ Проект запущен!${NC}"
        echo -e "${YELLOW}📱 Frontend: http://localhost${NC}"
        echo -e "${YELLOW}🔧 Backend API: http://localhost:8000${NC}"
        echo -e "${YELLOW}📚 API Docs: http://localhost:8000/docs${NC}"
        ;;
    2)
        echo -e "${CYAN}🚀 Запуск только backend...${NC}"
        docker-compose up -d backend
        echo ""
        echo -e "${GREEN}✅ Backend запущен!${NC}"
        echo -e "${YELLOW}🔧 Backend API: http://localhost:8000${NC}"
        echo -e "${YELLOW}📚 API Docs: http://localhost:8000/docs${NC}"
        ;;
    3)
        echo -e "${CYAN}🔨 Пересборка и запуск...${NC}"
        docker-compose up -d --build
        echo ""
        echo -e "${GREEN}✅ Проект пересобран и запущен!${NC}"
        echo -e "${YELLOW}📱 Frontend: http://localhost${NC}"
        echo -e "${YELLOW}🔧 Backend API: http://localhost:8000${NC}"
        ;;
    4)
        echo -e "${CYAN}🛑 Остановка всех контейнеров...${NC}"
        docker-compose down
        echo -e "${GREEN}✅ Все контейнеры остановлены${NC}"
        ;;
    5)
        echo -e "${CYAN}📋 Логи (Ctrl+C для выхода):${NC}"
        docker-compose logs -f
        ;;
    6)
        echo -e "${CYAN}📊 Статус контейнеров:${NC}"
        docker-compose ps
        ;;
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac
