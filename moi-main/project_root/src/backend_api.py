"""Backend API wrapper for video analysis.

Expose a single, well-named function with clear behavior that future
backend code can call without touching internal pipeline details.

Function:
  analyze_video_for_backend(video_path, confidence_threshold=0.7)

It returns a JSON-serializable dict with only essential data:
  - status: "ok" or "error"
  - exercise: detected exercise ("pushup" or "pullup")
  - confidence: confidence percentage (0-100)
  - technique_issues: list of detected technique problems
  - metrics: dict of measured angles/values
  - error: error message (if status == "error")
"""
from typing import Optional, Dict, Any, List
import logging
import json
import sys
from io import StringIO

from quick_predict import predict_video

logger = logging.getLogger(__name__)


def analyze_video_for_backend(video_path: str,
                              confidence_threshold: float = 0.7) -> Dict[str, Any]:
    """Run full analysis pipeline on `video_path` and return ONLY essential data for backend.

    This function:
      1. Analyzes video to detect exercise type and technique
      2. Suppresses verbose logs from internal pipeline
      3. Returns only: exercise, confidence, technique issues, and metrics
      4. Keeps internal complexity hidden from backend code

    Args:
        video_path: path to input video file (str).
        confidence_threshold: minimal confidence score (0.0-1.0) to trust result.

    Returns:
        Dict with keys:
          - status: "ok" or "error"
          - exercise: "pushup" or "pullup" (only if status == "ok")
          - confidence: float, percentage 0-100 (only if status == "ok")
          - technique_issues: list of problem strings (only if status == "ok")
          - metrics: dict of angle measurements (only if status == "ok")
          - error: str error message (only if status == "error")

    Example:
        >>> result = analyze_video_for_backend("/path/to/video.mp4")
        >>> if result["status"] == "ok":
        ...     print(f"Exercise: {result['exercise']}")
        ...     print(f"Confidence: {result['confidence']}%")
        ...     for issue in result['technique_issues']:
        ...         print(f"  Problem: {issue}")
    """
    try:
        # Suppress verbose logs from internal pipeline during analysis
        suppress_internal_logs()
        
        # Run full pipeline analysis
        pipeline_result = predict_video(video_path, confidence_threshold=confidence_threshold)
        
        # Extract only essential data for backend
        return {
            "status": "ok",
            "exercise": pipeline_result["exercise"],
            "confidence": float(pipeline_result["confidence"] * 100),  # Convert to percentage
            "technique_issues": pipeline_result["validation"].get("problems", []),
            "metrics": pipeline_result["validation"].get("metrics", {}),
            "error": None
        }
    except Exception as exc:
        logger.exception("analyze_video_for_backend failed")
        return {
            "status": "error",
            "exercise": None,
            "confidence": None,
            "technique_issues": [],
            "metrics": {},
            "error": str(exc)
        }
    finally:
        restore_internal_logs()


def suppress_internal_logs():
    """Temporarily suppress verbose logs from internal modules."""
    for logger_name in ["fitness_pose_extraction", "fitness_pipeline_manager", 
                        "quick_predict", "exercise_recognition_model"]:
        logging.getLogger(logger_name).setLevel(logging.WARNING)


def restore_internal_logs():
    """Restore normal log levels."""
    for logger_name in ["fitness_pose_extraction", "fitness_pipeline_manager", 
                        "quick_predict", "exercise_recognition_model"]:
        logging.getLogger(logger_name).setLevel(logging.INFO)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Запустить анализ видео через backend API wrapper")
    parser.add_argument("--video", required=True, help="Path to input video")
    parser.add_argument("--threshold", type=float, default=0.7, help="Confidence threshold")
    args = parser.parse_args()

    out = analyze_video_for_backend(args.video, confidence_threshold=args.threshold)
    print(json.dumps(out, ensure_ascii=False, indent=2))
