import secrets
from datetime import datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from app.enums import AccountStatus
from app.errors import BadRequestError, NotFoundError
from app.models.account import Account
from app.models.user import User
from app.repos import account_repo
from app.schemas.account import CreateAccountRequest


def _generate_account_number() -> str:
    return "".join(secrets.choice("0123456789") for _ in range(15))


def create_account(db: Session, user: User, req: CreateAccountRequest) -> Account:
    for _ in range(5):
        number = _generate_account_number()
        if account_repo.get_by_number(db, number) is None:
            break
    else:
        raise BadRequestError("Unable to allocate account number")

    account = Account(
        account_number=number,
        balance=Decimal("0"),
        account_type=req.account_type,
        currency=req.currency,
        status=AccountStatus.ACTIVE,
        user_id=user.id,
    )
    return account_repo.save(db, account)


def list_for_user(db: Session, user: User) -> list[Account]:
    return account_repo.list_for_user(db, user.id)


def get_for_user(db: Session, user: User, account_number: str) -> Account:
    account = account_repo.get_by_number(db, account_number)
    if account is None or account.user_id != user.id:
        raise NotFoundError("Account not found")
    return account


def close_for_user(db: Session, user: User, account_number: str) -> Account:
    account = get_for_user(db, user, account_number)
    if account.status == AccountStatus.CLOSED:
        raise BadRequestError("Account already closed")
    if account.balance != Decimal("0"):
        raise BadRequestError("Account balance must be zero before closing")
    account.status = AccountStatus.CLOSED
    account.closed_at = datetime.utcnow()
    return account_repo.save(db, account)
