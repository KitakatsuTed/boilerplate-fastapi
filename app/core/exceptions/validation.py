"""ValidationError exception."""

from app.core.exceptions.business import BusinessException


class ValidationError(BusinessException):
    """Exception raised when validation fails."""

    def __init__(self, message: str = "Validation error"):
        """Initialize ValidationError."""
        super().__init__(message, status_code=422)
