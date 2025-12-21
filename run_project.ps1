param (
    [string]$Mode = "local" # Options: "local", "docker"
)

$ErrorActionPreference = "Stop"

function Write-Color([string]$text, [ConsoleColor]$color) {
    Write-Host $text -ForegroundColor $color
}

function Test-Port($port) {
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect("127.0.0.1", $port)
        $tcp.Close()
        return $true
    } catch {
        return $false
    }
}

function Wait-For-Port($port, $name, $timeout=30) {
    Write-Host "Waiting for $name on port $port..." -NoNewline
    $start = Get-Date
    while ((Get-Date) - $start -lt (New-TimeSpan -Seconds $timeout)) {
        if (Test-Port $port) {
            Write-Host " Ready!" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline
    }
    Write-Host " Timeout!" -ForegroundColor Red
    return $false
}

if ($Mode -eq "docker") {
    Write-Color "Starting project in Docker..." Cyan
    docker-compose up --build
    exit
}

if ($Mode -ne "local") {
    Write-Color "Invalid mode. Use 'local' or 'docker'." Red
    exit 1
}

Write-Color "Starting project LOCALLY..." Cyan

# 1. Setup and Run Backend (Integrated Model)
Write-Color "`n[1/2] Setting up Backend API (with Integrated Model)..." Yellow
if (-not (Test-Path "backend/venv")) {
    Write-Color "Creating venv for backend..." Gray
    python -m venv backend/venv
}
Write-Color "Installing requirements for backend (this may take a while)..." Gray
& "backend/venv/Scripts/pip" install -r backend/requirements.txt | Out-Null

Write-Color "Starting Backend API on port 8000..." Green
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd backend; & 'venv/Scripts/uvicorn' app:app --reload --port 8000" -WorkingDirectory "$PWD"

# Wait for services to be ready
$backendReady = Wait-For-Port 8000 "Backend API"

if (-not $backendReady) {
    Write-Color "Backend failed to start properly. Please check the opened window for errors." Red
} else {
    Write-Color "Backend service is running!" Green
    
    # Test Backend Health
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health" -Method Get
        Write-Color "Backend Health Check: $($response.status)" Green
    } catch {
        Write-Color "Backend Health Check Failed: $_" Red
    }
}

# 2. Run Frontend
Write-Color "`n[2/2] Starting Frontend (Flutter)..." Yellow
$response = Read-Host "Do you want to run the frontend now? (y/n)"
if ($response -eq 'y') {
    cd frontend_proj
    flutter pub get
    flutter run
} else {
    Write-Color "Skipping frontend launch." Gray
}
