FROM python:3.9.6-slim

WORKDIR /app

# Install system dependencies for OpenCV
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install dependencies
# Install fastapi and uvicorn explicitly as they are not in requirements.txt
RUN pip install -r requirements.txt && \
    pip install fastapi uvicorn python-multipart

# Copy code
COPY . .

# Expose port
EXPOSE 8001

# Run server
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8001"]
