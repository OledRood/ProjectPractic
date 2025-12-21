#!/bin/bash
# Скрипт для быстрого тестирования нескольких видео

cd /Users/nikko/Downloads/moi-main/project_root

echo "═══════════════════════════════════════════════════════════════"
echo "ТЕСТИРОВАНИЕ PUSHUP ВИДЕО"
echo "═══════════════════════════════════════════════════════════════"
python src/test_backend_api.py --video data/dataset/video/pushups/video1.mp4 2>/dev/null | grep -A 20 "Status: OK"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "ТЕСТИРОВАНИЕ PULLUP ВИДЕО"
echo "═══════════════════════════════════════════════════════════════"
python src/test_backend_api.py --video data/dataset/video/pullups/video5.mp4 2>/dev/null | grep -A 20 "Status: OK"
