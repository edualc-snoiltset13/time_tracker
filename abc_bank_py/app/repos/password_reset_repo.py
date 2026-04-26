from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.models.password_reset import PasswordResetCode


def get_by_code(db: Session, code: str) -> PasswordResetCode | None:
    return db.execute(
        select(PasswordResetCode).where(PasswordResetCode.code == code)
    ).scalar_one_or_none()


def delete_for_user(db: Session, user_id: int) -> None:
    db.execute(delete(PasswordResetCode).where(PasswordResetCode.user_id == user_id))


def add(db: Session, prc: PasswordResetCode) -> PasswordResetCode:
    db.add(prc)
    db.commit()
    db.refresh(prc)
    return prc
