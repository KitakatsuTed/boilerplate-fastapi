"""ForbiddenError exception."""
from app.core.exceptions.business import BusinessException


class ForbiddenError(BusinessException):
    """Exception raised when access is forbidden."""

    def __init__(self, message: str = "Forbidden"):
        """Initialize ForbiddenError."""
        super().__init__(message, status_code=403)
