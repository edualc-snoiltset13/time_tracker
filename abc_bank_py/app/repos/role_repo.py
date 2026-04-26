from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import Role


def get_by_name(db: Session, name: str) -> Role | None:
    return db.execute(select(Role).where(Role.name == name)).scalar_one_or_none()


def get_or_create(db: Session, name: str) -> Role:
    role = get_by_name(db, name)
    if role is not None:
        return role
    role = Role(name=name)
    db.add(role)
    db.commit()
    db.refresh(role)
    return role
