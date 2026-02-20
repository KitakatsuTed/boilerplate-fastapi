#!/bin/bash
# docker-build.sh - Dockerイメージビルド

IMAGE_NAME=${1:-boilerplate-fastapi}
TAG=${2:-latest}

echo "🐳 Building Docker image: ${IMAGE_NAME}:${TAG}..."
docker build -t "${IMAGE_NAME}:${TAG}" .
echo "✅ Build complete!"
