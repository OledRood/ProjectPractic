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
from model_client import ModelClient

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/")
async def root():
    return {"message": "Backend is running. Go to /docs for API."}

# Configuration
UPLOAD_DIR = Path("/tmp/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Queue and Tasks
task_queue = asyncio.Queue(maxsize=100)
active_tasks = 0
MAX_CONCURRENT = 3
tasks = {}  # {task_id: task_data}

model_client = ModelClient()

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
        
    # Return the result as a JSON file download
    # We can create a temporary file or stream it.
    # Since the result is in memory (dict), we can return it as JSONResponse
    # But if frontend uses 'download', it might expect a file attachment.
    # Let's try returning JSONResponse first, as it's the cleanest proxy.
    # If frontend fails, we might need to force it as a file.
    return JSONResponse(content=task["result"])

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
            
            # Call model
            # Pass rotation if needed, or other args
            kwargs = {}
            if rotation:
                kwargs["rotation"] = rotation
                
            result = await model_client.process_video(video_path, **kwargs)
            
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
    asyncio.create_task(worker())

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host='0.0.0.0', port=8000)
