"""Exception handlers."""
from fastapi import Request, status
from fastapi.responses import JSONResponse

from app.core.exceptions.business import BusinessException


async def business_exception_handler(request: Request, exc: BusinessException) -> JSONResponse:
    """Handle business exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle general exceptions."""
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"},
    )
