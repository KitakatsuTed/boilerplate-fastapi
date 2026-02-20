"""User update schema."""

from pydantic import BaseModel, EmailStr


class UserUpdate(BaseModel):
    """Schema for updating User."""

    email: EmailStr | None = None
    password: str | None = None
    full_name: str | None = None
    is_active: bool | None = None
    is_superuser: bool | None = None
