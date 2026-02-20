"""Logging configuration."""

import logging
import sys

from pythonjsonlogger import jsonlogger

from app.core.config import settings


class CorrelationIdFilter(logging.Filter):
    """Add correlation ID to log records."""

    def filter(self, record: logging.LogRecord) -> bool:
        """Add correlation_id to log record."""
        from app.core.middlewares import correlation_id

        record.correlation_id = correlation_id.get("N/A")
        return True


def setup_logging() -> None:
    """Setup logging configuration."""
    # ルートロガー設定
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, settings.LOG_LEVEL.upper()))

    # ハンドラーをクリア
    root_logger.handlers.clear()

    # コンソールハンドラー
    handler = logging.StreamHandler(sys.stdout)

    # フォーマット設定（JSON or テキスト）
    if settings.LOG_FORMAT == "json":
        formatter = jsonlogger.JsonFormatter(
            "%(asctime)s %(levelname)s %(name)s %(correlation_id)s %(message)s",
            rename_fields={"asctime": "timestamp", "levelname": "level", "name": "logger"},
        )
    else:
        formatter = logging.Formatter(
            "%(asctime)s - %(levelname)s - %(name)s - [%(correlation_id)s] - %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    handler.setFormatter(formatter)

    # 相関IDフィルター追加
    handler.addFilter(CorrelationIdFilter())

    root_logger.addHandler(handler)


def get_logger(name: str) -> logging.Logger:
    """Get logger by name."""
    return logging.getLogger(name)
