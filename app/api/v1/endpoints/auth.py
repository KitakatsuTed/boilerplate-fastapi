"""Authentication endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.providers.base import BaseAuthProvider
from app.db.repositories.user import UserRepository
from app.db.session import get_db
from app.dependencies import get_auth_provider
from app.schemas.token import LoginRequest, Token
from app.schemas.user import UserCreate, UserResponse
from app.utils.security import hash_password, verify_password

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    """Register a new user."""
    user_repo = UserRepository(db)

    # Check if email already exists
    if await user_repo.email_exists(user_in.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Hash password
    user_data = user_in.model_dump()
    user_data["hashed_password"] = hash_password(user_data.pop("password"))

    # Create user
    user = await user_repo.create(user_data)
    return UserResponse.model_validate(user)


@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db),
    auth_provider: BaseAuthProvider = Depends(get_auth_provider),
) -> Token:
    """Login user and return token."""
    user_repo = UserRepository(db)

    # Get user by email
    user = await user_repo.get_by_email(login_data.email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    # Verify password
    if not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )

    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )

    # Create tokens
    access_token = await auth_provider.create_access_token({"sub": str(user.id)})

    # JWT provider has refresh token
    if hasattr(auth_provider, "create_refresh_token"):
        refresh_token = await auth_provider.create_refresh_token({"sub": str(user.id)})
        return Token(access_token=access_token, refresh_token=refresh_token)

    return Token(access_token=access_token)
