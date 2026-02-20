"""User response schema."""
from datetime import datetime

from app.schemas.user.base import UserBase


class UserResponse(UserBase):
    """Schema for User response."""

    id: int
    created_at: datetime
    updated_at: datetime
