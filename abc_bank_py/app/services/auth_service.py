import secrets
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.config import Settings
from app.enums import ROLE_CUSTOMER
from app.errors import AuthError, BadRequestError, NotFoundError
from app.models.password_reset import PasswordResetCode
from app.models.user import User
from app.repos import password_reset_repo, role_repo, user_repo
from app.schemas.auth import (
    LoginResponse,
    RegistrationRequest,
    ResetPasswordRequest,
    UpdatePasswordRequest,
)
from app.security.passwords import hash_password, verify_password
from app.security.tokens import generate_token

_RESET_CODE_TTL_MINUTES = 30


def register(db: Session, req: RegistrationRequest) -> User:
    if user_repo.get_by_email(db, req.email):
        raise BadRequestError("Email already registered")
    customer_role = role_repo.get_or_create(db, ROLE_CUSTOMER)
    user = User(
        first_name=req.first_name,
        last_name=req.last_name,
        email=req.email,
        phone_number=req.phone_number,
        password_hash=hash_password(req.password),
    )
    user.roles.append(customer_role)
    return user_repo.create(db, user)


def login(db: Session, email: str, password: str, settings: Settings) -> LoginResponse:
    user = user_repo.get_by_email(db, email)
    if user is None or not user.active or not verify_password(password, user.password_hash):
        raise AuthError("Invalid credentials")
    token = generate_token(user.email, settings)
    return LoginResponse(token=token, roles=user.role_names())


def request_password_reset(db: Session, email: str) -> str | None:
    """Generate a reset code if the user exists. Returns the code (caller may dispatch via email).

    For security, this returns ``None`` for unknown emails so callers can keep the response uniform.
    """
    user = user_repo.get_by_email(db, email)
    if user is None:
        return None
    password_reset_repo.delete_for_user(db, user.id)
    code = secrets.token_urlsafe(24)
    prc = PasswordResetCode(
        code=code,
        expiry_date=datetime.utcnow() + timedelta(minutes=_RESET_CODE_TTL_MINUTES),
        used=False,
        user_id=user.id,
    )
    password_reset_repo.add(db, prc)
    return code


def confirm_password_reset(db: Session, req: ResetPasswordRequest) -> None:
    prc = password_reset_repo.get_by_code(db, req.code)
    if prc is None or prc.used or prc.expiry_date < datetime.utcnow():
        raise BadRequestError("Invalid or expired code")
    user = user_repo.get_by_id(db, prc.user_id)
    if user is None or user.email != req.email:
        raise BadRequestError("Invalid or expired code")
    user.password_hash = hash_password(req.new_password)
    prc.used = True
    db.commit()


def change_password(db: Session, user: User, req: UpdatePasswordRequest) -> None:
    if not verify_password(req.old_password, user.password_hash):
        raise AuthError("Invalid credentials")
    if req.old_password == req.new_password:
        raise BadRequestError("New password must differ from current")
    user.password_hash = hash_password(req.new_password)
    db.commit()


def get_user_or_404(db: Session, email: str) -> User:
    user = user_repo.get_by_email(db, email)
    if user is None:
        raise NotFoundError("User not found")
    return user
