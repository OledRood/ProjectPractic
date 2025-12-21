from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import shutil
import os
from pathlib import Path
import sys

# Add project_root to sys.path to import src
# Assuming this file is in moi-main/ and project_root is moi-main/project_root
sys.path.append(str(Path(__file__).parent / "project_root"))

try:
    from src.backend_api import analyze_video_for_backend
except ImportError:
    # Fallback if running from different context or structure is different
    sys.path.append(str(Path(__file__).parent))
    from project_root.src.backend_api import analyze_video_for_backend

app = FastAPI()

@app.post("/predict")
async def predict(video: UploadFile = File(...)):
    # Create temp directory if not exists
    Path("/tmp").mkdir(exist_ok=True)
    
    temp_file = Path(f"/tmp/{video.filename}")
    with open(temp_file, "wb") as buffer:
        shutil.copyfileobj(video.file, buffer)
        
    try:
        # Call the analysis function
        result = analyze_video_for_backend(str(temp_file))
        return JSONResponse(content=result)
    except Exception as e:
        return JSONResponse(content={"status": "error", "error": str(e)}, status_code=500)
    finally:
        if temp_file.exists():
            temp_file.unlink()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
