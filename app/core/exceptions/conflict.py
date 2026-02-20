"""ConflictError exception."""

from app.core.exceptions.business import BusinessException


class ConflictError(BusinessException):
    """Exception raised when a conflict occurs."""

    def __init__(self, message: str = "Conflict"):
        """Initialize ConflictError."""
        super().__init__(message, status_code=409)
