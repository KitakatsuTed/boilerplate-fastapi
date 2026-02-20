#!/bin/bash
# docker-test.sh - Dockerイメージヘルスチェック自動化

IMAGE_NAME=${1:-boilerplate-fastapi}
TAG=${2:-latest}
CONTAINER_NAME="test-${IMAGE_NAME}"

echo "🐳 Testing Docker image: ${IMAGE_NAME}:${TAG}..."

# コンテナ起動
echo "🚀 Starting container..."
docker run -d --name "${CONTAINER_NAME}" -p 8000:8000 "${IMAGE_NAME}:${TAG}"

# ヘルスチェック
echo "🏥 Waiting for health check..."
sleep 5

# ヘルスエンドポイントをチェック
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)

# クリーンアップ
docker stop "${CONTAINER_NAME}" > /dev/null 2>&1
docker rm "${CONTAINER_NAME}" > /dev/null 2>&1

# 結果判定
if [ "$HEALTH_STATUS" == "200" ]; then
    echo "✅ Health check passed!"
    exit 0
else
    echo "❌ Health check failed! (HTTP $HEALTH_STATUS)"
    exit 1
fi
