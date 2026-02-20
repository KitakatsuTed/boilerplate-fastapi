"""Base authentication provider."""

from abc import ABC, abstractmethod
from typing import Any, Dict


class BaseAuthProvider(ABC):
    """Abstract base class for authentication providers."""

    @abstractmethod
    async def create_access_token(self, data: Dict[str, Any]) -> str:
        """Create access token."""
        pass

    @abstractmethod
    async def verify_token(self, token: str) -> Dict[str, Any] | None:
        """Verify and decode token."""
        pass

    @abstractmethod
    async def get_current_user(self, token: str) -> Any:
        """Get current user from token."""
        pass
