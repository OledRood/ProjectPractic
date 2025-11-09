#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  FastAPI Backend для обработки видео${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 не найден. Установите Python 3.${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Python найден: $(python3 --version)"
echo ""

# Проверка наличия pip
if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}❌ pip3 не найден. Установите pip.${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} pip найден"
echo ""

# Установка зависимостей
echo -e "${YELLOW}📦 Установка зависимостей...${NC}"
pip3 install -r requirements.txt -q

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Зависимости установлены"
else
    echo -e "${RED}❌ Ошибка установки зависимостей${NC}"
    exit 1
fi
echo ""

# Создание необходимых директорий
mkdir -p uploads results

echo -e "${GREEN}✓${NC} Директории созданы"
echo ""

# Запуск сервера
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   🚀 Запуск FastAPI сервера...${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}🌐 Сервер доступен по адресу:${NC}"
echo -e "${GREEN}   http://localhost:8000${NC}"
echo ""
echo -e "${YELLOW}📖 Интерактивная документация API:${NC}"
echo -e "${BLUE}   http://localhost:8000/docs${NC}"
echo ""
echo -e "${YELLOW}📚 ReDoc документация:${NC}"
echo -e "${BLUE}   http://localhost:8000/redoc${NC}"
echo ""
echo -e "${YELLOW}Для остановки нажмите Ctrl+C${NC}"
echo ""
echo -e "${GREEN}========================================${NC}"
echo ""

python3 app.py
