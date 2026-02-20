#!/bin/bash
# dev.sh - 開発サーバー起動

echo "🚀 Starting development server..."
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
