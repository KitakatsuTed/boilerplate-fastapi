"""User base schema."""

from pydantic import BaseModel, ConfigDict, EmailStr


class UserBase(BaseModel):
    """Base schema for User."""

    model_config = ConfigDict(from_attributes=True)

    email: EmailStr
    full_name: str | None = None
    is_active: bool = True
    is_superuser: bool = False
