"""Token schema."""
from pydantic import BaseModel


class Token(BaseModel):
    """Token schema."""

    access_token: str
    token_type: str = "bearer"
    refresh_token: str | None = None
