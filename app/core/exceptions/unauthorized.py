"""UnauthorizedError exception."""

from app.core.exceptions.business import BusinessException


class UnauthorizedError(BusinessException):
    """Exception raised when authentication fails."""

    def __init__(self, message: str = "Unauthorized"):
        """Initialize UnauthorizedError."""
        super().__init__(message, status_code=401)
