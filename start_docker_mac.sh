#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Starting Project in Docker (macOS)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo "Please install Docker Desktop and try again."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker daemon is not running.${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "Building and starting containers..."
docker-compose up -d --build

echo "Waiting for backend to be ready..."
sleep 10

echo "Starting Frontend (Flutter)..."
cd frontend_proj

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Error: Flutter is not installed.${NC}"
    exit 1
fi

flutter run -d chrome --web-port=3000
