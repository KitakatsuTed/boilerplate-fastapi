"""Token schemas."""

from app.schemas.token.login_request import LoginRequest
from app.schemas.token.token import Token

__all__ = [
    "Token",
    "LoginRequest",
]
