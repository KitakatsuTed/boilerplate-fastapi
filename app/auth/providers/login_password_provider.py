"""Login/Password (Session) authentication provider."""

import secrets
from datetime import timedelta
from typing import Any, Dict

from fastapi import HTTPException, status
from itsdangerous import BadSignature, SignatureExpired, TimestampSigner

from app.auth.providers.base import BaseAuthProvider
from app.core.config import settings


class LoginPasswordProvider(BaseAuthProvider):
    """Login/Password session authentication provider."""

    def __init__(self):
        """Initialize session provider."""
        if not settings.SESSION_SECRET_KEY:
            raise ValueError("SESSION_SECRET_KEY is required for session authentication")
        self.signer = TimestampSigner(settings.SESSION_SECRET_KEY)
        self.max_age = settings.SESSION_EXPIRE_MINUTES * 60  # Convert to seconds

    async def create_access_token(self, data: Dict[str, Any], expires_delta: timedelta | None = None) -> str:
        """Create session token."""
        # Generate random session ID
        session_id = secrets.token_urlsafe(32)

        # Sign session ID with timestamp
        signed_session = self.signer.sign(f"{session_id}:{data.get('sub', '')}").decode()
        return signed_session

    async def create_session(self, user_id: int) -> str:
        """Create session for user."""
        return await self.create_access_token({"sub": str(user_id)})

    async def verify_token(self, token: str) -> Dict[str, Any] | None:
        """Verify and decode session token."""
        try:
            # Unsign and verify timestamp
            unsigned = self.signer.unsign(token, max_age=self.max_age).decode()

            # Extract session_id and user_id
            session_id, user_id = unsigned.split(":", 1)

            return {"sub": user_id, "session_id": session_id}

        except SignatureExpired:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Session has expired",
            ) from None
        except (BadSignature, ValueError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid session",
            ) from None

    async def verify_session(self, session_token: str) -> Dict[str, Any] | None:
        """Verify session token."""
        return await self.verify_token(session_token)

    async def delete_session(self, session_token: str) -> None:
        """Delete session."""
        # セッショントークンベースの場合、署名を無効化するだけ
        # DBベースのセッション管理を実装する場合は、ここでDBから削除
        pass

    async def get_current_user(self, token: str) -> Any:
        """Get current user from session token."""
        payload = await self.verify_token(token)
        if payload is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
            )
        return payload
