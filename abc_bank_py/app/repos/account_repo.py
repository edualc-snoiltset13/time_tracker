from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.account import Account


def get_by_id(db: Session, account_id: int) -> Account | None:
    return db.get(Account, account_id)


def get_by_number(db: Session, account_number: str) -> Account | None:
    return db.execute(
        select(Account).where(Account.account_number == account_number)
    ).scalar_one_or_none()


def get_by_number_for_update(db: Session, account_number: str) -> Account | None:
    """Lock the account row for the duration of the surrounding transaction."""
    stmt = select(Account).where(Account.account_number == account_number)
    if db.bind is not None and db.bind.dialect.name != "sqlite":
        stmt = stmt.with_for_update()
    return db.execute(stmt).scalar_one_or_none()


def list_for_user(db: Session, user_id: int) -> list[Account]:
    return list(db.execute(select(Account).where(Account.user_id == user_id)).scalars())


def save(db: Session, account: Account) -> Account:
    db.add(account)
    db.commit()
    db.refresh(account)
    return account
