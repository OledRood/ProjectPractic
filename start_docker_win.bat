@echo off
echo ========================================
echo   Starting Project (Backend in Docker, Frontend Local)
echo ========================================
echo.

REM Check if Docker is installed/running
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Docker is not installed or not in PATH.
    echo Please install Docker Desktop and try again.
    pause
    exit /b 1
)

echo [1/2] Starting Backend and Model in Docker...
docker-compose up -d --build

if %errorlevel% neq 0 (
    echo.
    echo Error occurred during docker-compose up.
    pause
    exit /b 1
)

echo.
echo Backend started in background.
echo Waiting 10 seconds for services to initialize...
timeout /t 10 /nobreak >nul

echo.
echo [2/2] Starting Frontend (Flutter)...
cd frontend_proj

REM Check if Flutter is installed
call flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH.
    pause
    exit /b 1
)

echo Launching Flutter Web...
call flutter run -d chrome --web-port=3000

if %errorlevel% neq 0 (
    echo.
    echo Error occurred running Flutter.
    pause
)
