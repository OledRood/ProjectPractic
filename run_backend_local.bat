@echo off
echo ========================================
echo   Starting Backend Locally
echo ========================================
echo.

cd backend

REM Check if venv exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

echo Activating virtual environment...
call venv\Scripts\activate

echo Installing requirements...
pip install -r requirements.txt

echo.
echo Starting Server...
echo.
echo IMPORTANT:
echo Open http://localhost:8000 in your browser.
echo DO NOT use 0.0.0.0 in the browser (it does not work on Windows).
echo.

REM Set environment variable for model service (assuming local model for now)
set MODEL_SERVICE_URL=http://localhost:8001

REM Start server and open browser
start "" "http://localhost:8000"
python app.py

pause
