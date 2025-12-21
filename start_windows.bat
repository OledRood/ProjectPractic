@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ===========================================
:: Скрипт запуска проекта для Windows
:: ===========================================

echo ========================================
echo     Запуск проекта в Docker
echo ========================================

:: Проверка Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ОШИБКА] Docker не установлен!
    echo Установите Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

:: Проверка что Docker запущен
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ОШИБКА] Docker не запущен!
    echo Запустите Docker Desktop и попробуйте снова.
    pause
    exit /b 1
)

echo [OK] Docker доступен
echo.

:: Переход в директорию проекта
cd /d "%~dp0"

:: Меню выбора режима
echo Выберите режим запуска:
echo 1) Запустить всё (backend + frontend) - РЕКОМЕНДУЕТСЯ
echo 2) Только backend (без frontend)
echo 3) Пересобрать и запустить (--build)
echo 4) Остановить все контейнеры
echo 5) Посмотреть логи
echo 6) Статус контейнеров
echo.
set /p choice="Ваш выбор [1-6]: "

if "%choice%"=="1" (
    echo.
    echo [INFO] Запуск всех сервисов...
    docker-compose up -d
    echo.
    echo [OK] Проект запущен!
    echo     Frontend: http://localhost
    echo     Backend API: http://localhost:8000
    echo     API Docs: http://localhost:8000/docs
    goto :end
)

if "%choice%"=="2" (
    echo.
    echo [INFO] Запуск только backend...
    docker-compose up -d backend
    echo.
    echo [OK] Backend запущен!
    echo     Backend API: http://localhost:8000
    echo     API Docs: http://localhost:8000/docs
    goto :end
)

if "%choice%"=="3" (
    echo.
    echo [INFO] Пересборка и запуск...
    docker-compose up -d --build
    echo.
    echo [OK] Проект пересобран и запущен!
    echo     Frontend: http://localhost
    echo     Backend API: http://localhost:8000
    goto :end
)

if "%choice%"=="4" (
    echo.
    echo [INFO] Остановка всех контейнеров...
    docker-compose down
    echo [OK] Все контейнеры остановлены
    goto :end
)

if "%choice%"=="5" (
    echo.
    echo [INFO] Логи (Ctrl+C для выхода):
    docker-compose logs -f
    goto :end
)

if "%choice%"=="6" (
    echo.
    echo [INFO] Статус контейнеров:
    docker-compose ps
    goto :end
)

echo [ОШИБКА] Неверный выбор
goto :end

:end
echo.
pause
