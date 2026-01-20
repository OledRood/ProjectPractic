from fastapi import FastAPI, File, UploadFile, BackgroundTasks, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
import asyncio
from collections import deque
from pathlib import Path
import uuid
import aiofiles
import logging
import os
import time
import json
import sys
import numpy as np

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def convert_numpy(obj):
    if isinstance(obj, (np.integer, np.int64, np.int32)):
        return int(obj)
    elif isinstance(obj, (np.floating, np.float64, np.float32)):
        return float(obj)
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    raise TypeError(f"Object of type {type(obj)} is not JSON serializable")

# В Docker: модель находится в /app/model (через PYTHONPATH)
# Локально: модель находится в ../moi-main/project_root
MODEL_ROOT_DOCKER = Path("/app/model")
MODEL_ROOT_LOCAL = Path(__file__).parent.parent / "moi-main" / "project_root"

if MODEL_ROOT_DOCKER.exists():
    MODEL_ROOT = MODEL_ROOT_DOCKER
    logger.info(f"Using Docker model path: {MODEL_ROOT}")
else:
    MODEL_ROOT = MODEL_ROOT_LOCAL
    logger.info(f"Using local model path: {MODEL_ROOT}")

sys.path.insert(0, str(MODEL_ROOT / "src"))
sys.path.insert(0, str(MODEL_ROOT))

# Импорт модели с обработкой ошибок
analyze_video_for_backend = None
try:
    from backend_api import analyze_video_for_backend
    logger.info("✅ Model imported successfully")
except ImportError as e:
    logger.error(f"❌ Failed to import model: {e}")
    logger.error(f"   MODEL_ROOT: {MODEL_ROOT}")
    logger.error(f"   sys.path: {sys.path[:3]}...")


app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/")
async def root():
    return {"message": "Backend is running (Integrated Model). Go to /docs for API."}

UPLOAD_DIR = Path("tmp/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

task_queue = asyncio.Queue(maxsize=100)
active_tasks = 0
MAX_CONCURRENT = 1 # Reduce concurrency since model is heavy
tasks = {}  # {task_id: task_data}

# Эндпоинты
@app.get("/api/health")
async def health_check():
    return {"status": "ok"}

@app.post("/api/upload")
async def upload_video(file: UploadFile = File(...), rotation: int = Form(None)):
    task_id = str(uuid.uuid4())
    video_path = UPLOAD_DIR / f"{task_id}.mp4"
    
    # Save file
    async with aiofiles.open(video_path, "wb") as f:
        content = await file.read()
        await f.write(content)
    
    now = time.time()
    task_data = {
        "task_id": task_id,
        "status": "queued",
        "created_at": now,
        "updated_at": now,
        "video_path": str(video_path),
        "rotation": rotation
    }
    
    tasks[task_id] = task_data
    await task_queue.put(task_id)
    
    return {
        "task_id": task_id, 
        "status": "queued",
        "created_at": now,
        "updated_at": now
    }

@app.get("/api/status/{task_id}")
async def get_status(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id].copy()
    # Remove internal paths before sending
    if "video_path" in task:
        del task["video_path"]
    
    try:
        # Use json.loads(json.dumps(...)) to recursively convert all numpy types
        clean_task = json.loads(json.dumps(task, default=convert_numpy))
        return clean_task
    except Exception as e:
        logger.error(f"JSON serialization failed in get_status: {e}")
        # Fallback: return task as is (might fail if it has numpy types)
        return task

@app.get("/api/result/{task_id}")
async def get_result(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task = tasks[task_id]
    if task["status"] != "completed":
        raise HTTPException(status_code=400, detail="Task not completed")
    
    if "result" not in task:
        raise HTTPException(status_code=404, detail="Result not found")
        
    output_filename = f"{task_id}_skeleton.mp4"
    output_path = MODEL_ROOT / "data" / "output_videos" / output_filename
    
    if output_path.exists():
        logger.info(f"Serving processed video: {output_path}")
        return FileResponse(output_path, media_type="video/mp4", filename=output_filename)
    else:
        logger.error(f"Processed video not found at {output_path}")
        # If video is missing but task is completed, it's an error state for the video file
        raise HTTPException(status_code=404, detail="Processed video file not found")

async def worker():
    global active_tasks
    logger.info("Worker started")
    while True:
        if active_tasks >= MAX_CONCURRENT:
            await asyncio.sleep(1)
            continue
            
        task_id = await task_queue.get()
        active_tasks += 1
        
        try:
            logger.info(f"Processing task {task_id}")
            tasks[task_id]["status"] = "processing"
            tasks[task_id]["updated_at"] = time.time()
            tasks[task_id]["stage"] = "processing"
            tasks[task_id]["progress"] = 0.0
            
            video_path = Path(tasks[task_id]["video_path"])
            rotation = tasks[task_id].get("rotation")
            
            # Call model directly in thread pool to avoid blocking
            logger.info(f"Starting model analysis for {video_path}")
            
            if analyze_video_for_backend is None:
                raise RuntimeError("Model not loaded. Check logs for import errors.")
            
            result = await asyncio.to_thread(analyze_video_for_backend, str(video_path))
            
            tasks[task_id]["status"] = "completed"
            tasks[task_id]["result"] = result
            tasks[task_id]["progress"] = 1.0
            tasks[task_id]["stage"] = "completed"
            
        except Exception as e:
            logger.error(f"Task {task_id} failed: {e}")
            tasks[task_id]["status"] = "failed"
            tasks[task_id]["error"] = str(e)
        finally:
            tasks[task_id]["updated_at"] = time.time()
            active_tasks -= 1
            # Cleanup video file
            try:
                Path(tasks[task_id]["video_path"]).unlink(missing_ok=True)
            except Exception as e:
                logger.error(f"Failed to delete temp file: {e}")

@app.on_event("startup")
async def startup():
    logger.info("------------------------------------------------")
    logger.info(f"Backend started (Integrated Model Mode).")
    logger.info(f"Upload Directory: {UPLOAD_DIR}")
    logger.info(f"Model Root: {MODEL_ROOT}")
    logger.info("------------------------------------------------")
    asyncio.create_task(worker())

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8000)
