import httpx
from pathlib import Path
import logging
import os

logger = logging.getLogger(__name__)

class ModelClient:
    def __init__(self):
        # Use environment variable for flexibility, default to docker service name
        self.base_url = os.getenv("MODEL_SERVICE_URL", "http://moi_model:8001")
        
    async def process_video(self, video_path: Path, **kwargs):
        """Передаем видео в moi_model и возвращаем ЕЁ ответ 1:1"""
        async with httpx.AsyncClient(timeout=300.0) as client: # Increased timeout for video processing
            with open(video_path, "rb") as f:
                # Pass all kwargs as query params or json? 
                # The user example used json=kwargs.
                # But if the model expects form data + file, json might not work directly with files in some frameworks.
                # However, FastAPI can handle files and form data.
                # Let's stick to the user's example but be careful.
                # If kwargs are simple types, we can pass them as data (form fields).
                
                # Converting kwargs to string values for form data if needed, 
                # but user example said `json=kwargs`. 
                # If the model endpoint is FastAPI:
                # @app.post("/predict")
                # async def predict(video: UploadFile, data: dict = Body(...))
                # Then json=kwargs works if it's a separate field.
                # But usually with files, we use data=...
                
                # Let's assume the model server (which I will write) accepts multipart/form-data
                # where 'video' is the file and other params are form fields.
                
                # User example:
                # response = await client.post(
                #     f"{self.base_url}/predict",
                #     files={"video": f},
                #     json=kwargs
                # )
                
                # I will follow this exactly.
                response = await client.post(
                    f"{self.base_url}/predict",
                    files={"video": f},
                    data=kwargs # Using data for form fields is safer with files than json body
                )
            response.raise_for_status()
            # ✅ ВОЗВРАЩАЕМ ТОЧНО ТОТ JSON, КОТОРЫЙ ПРИШЕЛ ОТ МОДЕЛИ
            return response.json()
