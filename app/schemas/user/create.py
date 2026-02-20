"""User create schema."""
from app.schemas.user.base import UserBase


class UserCreate(UserBase):
    """Schema for creating User."""

    password: str
