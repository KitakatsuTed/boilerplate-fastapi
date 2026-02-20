"""Middleware configurations."""
import uuid
from contextvars import ContextVar

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

# 相関IDをスレッドセーフに管理
correlation_id: ContextVar[str] = ContextVar("correlation_id", default="N/A")


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Middleware to add correlation ID to requests."""

    async def dispatch(self, request: Request, call_next):
        """Add correlation ID to request."""
        # リクエストヘッダーから相関IDを取得、なければ生成
        cid = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))

        # ContextVarに設定
        correlation_id.set(cid)

        # リクエスト処理
        response = await call_next(request)

        # レスポンスヘッダーに相関IDを追加
        response.headers["X-Correlation-ID"] = cid

        return response
