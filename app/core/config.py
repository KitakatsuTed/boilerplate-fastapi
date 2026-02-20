"""Application configuration."""

import json
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=True)

    # プロジェクト情報
    PROJECT_NAME: str = "FastAPI Boilerplate"
    VERSION: str = "1.0.0"

    # 認証タイプ (jwt, login_password, oauth2, none)
    AUTH_TYPE: str = "jwt"

    # データベースタイプ (postgresql, mysql, sqlite)
    DB_TYPE: str = "postgresql"

    # セキュリティ
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # セッション認証設定
    SESSION_SECRET_KEY: str | None = None
    SESSION_EXPIRE_MINUTES: int = 60

    # PostgreSQL設定
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "fastapi_db"
    POSTGRES_PORT: int = 5432

    # MySQL設定
    MYSQL_SERVER: str | None = None
    MYSQL_USER: str | None = None
    MYSQL_PASSWORD: str | None = None
    MYSQL_DB: str | None = None
    MYSQL_PORT: int = 3306

    # SQLite設定
    SQLITE_DB_PATH: str = "./data/app.db"

    # AI連携
    AI_PROVIDER: str = "bedrock"
    AWS_REGION: str = "us-east-1"
    AWS_BEDROCK_MODEL_ID: str = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8000"]

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: str | List[str]) -> List[str]:
        """Parse CORS origins from string or list."""
        if isinstance(v, str):
            return json.loads(v)
        return v

    # ロギング
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # json or text

    @property
    def DATABASE_URL(self) -> str:
        """Generate database URL based on DB_TYPE."""
        if self.DB_TYPE == "postgresql":
            return (
                f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
                f"@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
            )
        elif self.DB_TYPE == "mysql":
            if not self.MYSQL_SERVER or not self.MYSQL_USER or not self.MYSQL_PASSWORD or not self.MYSQL_DB:
                raise ValueError("MySQL configuration is incomplete")
            return (
                f"mysql+aiomysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}"
                f"@{self.MYSQL_SERVER}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
            )
        elif self.DB_TYPE == "sqlite":
            return f"sqlite+aiosqlite:///{self.SQLITE_DB_PATH}"
        else:
            raise ValueError(f"Unsupported database type: {self.DB_TYPE}")


# シングルトンインスタンス
settings = Settings()
