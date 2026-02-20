"""Business exception base class."""


class BusinessException(Exception):
    """Base class for business exceptions."""

    def __init__(self, message: str, status_code: int = 400):
        """Initialize business exception."""
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)
