#!/bin/bash

# Function to check if a process is running on a port
check_port() {
    if lsof -i:$1 > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Start backend
echo "Starting backend server..."
cd backend
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    source venv/bin/activate
fi

# Start backend in the background
python app.py &
BACKEND_PID=$!
echo "Backend server started (PID: $BACKEND_PID)"

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
while ! check_port 8000; do
    sleep 1
done
echo "Backend is ready!"

# Start frontend
echo "Starting frontend..."
cd ../frontend_proj

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed"
    exit 1
fi

# Run flutter web
flutter run -d chrome --web-port=3000

# Function to handle script termination
cleanup() {
    echo "Stopping services..."
    kill $BACKEND_PID
    exit 0
}

# Set up cleanup on script termination
trap cleanup SIGINT SIGTERM

# Wait for user interrupt
wait