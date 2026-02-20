"""InternalServerError exception."""

from app.core.exceptions.business import BusinessException


class InternalServerError(BusinessException):
    """Exception raised when an internal server error occurs."""

    def __init__(self, message: str = "Internal server error"):
        """Initialize InternalServerError."""
        super().__init__(message, status_code=500)
