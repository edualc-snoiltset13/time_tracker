from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.config import Settings, get_settings
from app.db import get_db
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    RegistrationRequest,
    RequestPasswordResetRequest,
    ResetPasswordRequest,
    UpdatePasswordRequest,
    UserDTO,
)
from app.security.deps import get_current_user
from app.services import auth_service

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/register", response_model=UserDTO, status_code=status.HTTP_201_CREATED)
def register(req: RegistrationRequest, db: Session = Depends(get_db)) -> UserDTO:
    user = auth_service.register(db, req)
    return UserDTO(
        id=user.id,
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        phone_number=user.phone_number,
        active=user.active,
        created_at=user.created_at,
        roles=user.role_names(),
    )


@router.post("/login", response_model=LoginResponse)
def login(
    req: LoginRequest,
    db: Session = Depends(get_db),
    settings: Settings = Depends(get_settings),
) -> LoginResponse:
    return auth_service.login(db, req.email, req.password, settings)


@router.post("/password/reset/request", status_code=status.HTTP_202_ACCEPTED)
def request_password_reset(
    req: RequestPasswordResetRequest, db: Session = Depends(get_db)
) -> dict[str, str]:
    auth_service.request_password_reset(db, req.email)
    return {"detail": "If that email exists, a reset code has been issued"}


@router.post("/password/reset/confirm")
def confirm_password_reset(
    req: ResetPasswordRequest, db: Session = Depends(get_db)
) -> dict[str, str]:
    auth_service.confirm_password_reset(db, req)
    return {"detail": "Password reset"}


@router.post("/password/change")
def change_password(
    req: UpdatePasswordRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict[str, str]:
    auth_service.change_password(db, user, req)
    return {"detail": "Password updated"}
