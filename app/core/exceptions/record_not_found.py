"""RecordNotFoundError exception."""

from app.core.exceptions.business import BusinessException


class RecordNotFoundError(BusinessException):
    """Exception raised when a record is not found."""

    def __init__(self, message: str = "Record not found"):
        """Initialize RecordNotFoundError."""
        super().__init__(message, status_code=404)
