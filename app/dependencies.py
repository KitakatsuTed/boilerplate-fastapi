"""Dependency injection providers."""
from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.providers.base import BaseAuthProvider
from app.auth.providers.jwt_provider import JWTProvider
from app.auth.providers.login_password_provider import LoginPasswordProvider
from app.core.config import settings
from app.db.repositories.user import UserRepository
from app.db.session import get_db
from app.models.user import User


def get_auth_provider() -> BaseAuthProvider:
    """Get authentication provider based on AUTH_TYPE."""
    if settings.AUTH_TYPE == "jwt":
        return JWTProvider()
    elif settings.AUTH_TYPE == "login_password":
        return LoginPasswordProvider()
    else:
        raise ValueError(f"Unsupported authentication type: {settings.AUTH_TYPE}")


async def get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db),
    auth_provider: BaseAuthProvider = Depends(get_auth_provider),
) -> User:
    """Get current user from token."""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Extract token from "Bearer <token>"
    try:
        scheme, token = authorization.split()
        if scheme.lower() != "bearer":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication scheme",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify token and get payload
    payload = await auth_provider.verify_token(token)
    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Get user from database
    user_repo = UserRepository(db)
    user = await user_repo.get_by_id(int(user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


async def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """Get current active user."""
    if not current_user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
    return current_user


__all__ = [
    "get_db",
    "get_auth_provider",
    "get_current_user",
    "get_current_active_user",
]
