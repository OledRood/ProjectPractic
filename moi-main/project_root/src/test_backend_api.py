#!/usr/bin/env python3
"""Quick test script for backend_api.

Usage:
    python src/test_backend_api.py --video path/to/video.mp4
"""
import argparse
import json
from pathlib import Path

from backend_api import analyze_video_for_backend


def main():
    parser = argparse.ArgumentParser(description="Test backend_api.analyze_video_for_backend()")
    parser.add_argument("--video", required=True, help="Path to video file")
    args = parser.parse_args()

    video_path = Path(args.video)
    if not video_path.exists():
        print(f"❌ Video not found: {video_path}")
        return

    print(f"\n📹 Analyzing: {video_path.name}")
    print("=" * 80)

    # Call the backend API function
    result = analyze_video_for_backend(str(video_path), confidence_threshold=0.7)

    # Pretty print results
    if result["status"] == "ok":
        print(f"✅ Status: OK\n")
        print(f"🏋️  Exercise: {result['exercise'].upper()}")
        print(f"💯 Confidence: {result['confidence']:.1f}%")
        
        if result["technique_issues"]:
            print(f"\n⚠️  Technique Issues:")
            for issue in result["technique_issues"]:
                print(f"   • {issue}")
        else:
            print(f"\n✨ No technique issues detected!")
        
        if result["metrics"]:
            print(f"\n📊 Metrics:")
            for key, value in result["metrics"].items():
                if isinstance(value, float):
                    print(f"   {key}: {value:.2f}°")
                else:
                    print(f"   {key}: {value}")
    else:
        print(f"❌ Status: ERROR")
        print(f"Error: {result['error']}")

    print("=" * 80)
    print(f"\nRaw JSON output:")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
