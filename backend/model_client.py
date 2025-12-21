import httpx
from pathlib import Path
import logging
import os
import asyncio

logger = logging.getLogger(__name__)

class ModelClient:
    def __init__(self):
        # Use environment variable for flexibility
        self.base_url = os.getenv("MODEL_SERVICE_URL")
        
        if not self.base_url:
            # Если переменная не задана, пытаемся определить окружение
            if os.name == 'nt': # Windows - скорее всего локальный запуск
                self.base_url = "http://127.0.0.1:8001"
                logger.info("Running on Windows, defaulting to local model service: http://127.0.0.1:8001")
            else: # Linux/Docker
                self.base_url = "http://moi_model:8001"
                logger.info("Defaulting to docker service: http://moi_model:8001")
        
        # Fix localhost -> 127.0.0.1 just in case
        if "localhost" in self.base_url:
             self.base_url = self.base_url.replace("localhost", "127.0.0.1")
             
        logger.info(f"ModelClient initialized with URL: {self.base_url}")

    async def process_video(self, video_path: Path, **kwargs):
        """Передаем видео в moi_model и возвращаем ЕЁ ответ 1:1"""
        
        logger.info(f"Sending video to model service at: {self.base_url}/predict")
        try:
            async with httpx.AsyncClient(timeout=300.0) as client: # Increased timeout for video processing
                with open(video_path, "rb") as f:
                    response = await client.post(
                        f"{self.base_url}/predict",
                        files={"video": f},
                        data=kwargs 
                    )
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Error communicating with model service: {e}")
            raise
