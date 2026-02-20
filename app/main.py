"""FastAPI application entrypoint."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings
from app.core.exceptions.business import BusinessException
from app.core.handlers import business_exception_handler, general_exception_handler
from app.core.logger import get_logger, setup_logging
from app.core.middlewares import CorrelationIdMiddleware

# ロギング設定
setup_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info(f"Database: {settings.DB_TYPE}")
    logger.info(f"Authentication: {settings.AUTH_TYPE}")
    yield
    # Shutdown
    logger.info(f"Shutting down {settings.PROJECT_NAME}")


# FastAPIアプリケーション初期化
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    lifespan=lifespan,
)

# 例外ハンドラー登録
app.add_exception_handler(BusinessException, business_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# ミドルウェア登録（順序重要：後に追加されたものが先に実行される）
# 1. CORSミドルウェア
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. 相関IDミドルウェア
app.add_middleware(CorrelationIdMiddleware)

# ヘルスチェックエンドポイント
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "database": settings.DB_TYPE,
        "auth": settings.AUTH_TYPE,
    }


# ルーター登録
app.include_router(api_router, prefix="/api/v1")
