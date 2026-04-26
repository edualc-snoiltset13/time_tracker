from decimal import Decimal

from sqlalchemy.orm import Session

from app.enums import AccountStatus, TransactionStatus, TransactionType
from app.errors import (
    InsufficientBalanceError,
    InvalidTransactionError,
    NotFoundError,
)
from app.models.account import Account
from app.models.transaction import Transaction
from app.models.user import User
from app.repos import account_repo


def _own_active_account(
    db: Session, user: User, account_number: str
) -> Account:
    account = account_repo.get_by_number_for_update(db, account_number)
    if account is None or account.user_id != user.id:
        raise NotFoundError("Account not found")
    if account.status != AccountStatus.ACTIVE:
        raise InvalidTransactionError("Account is not active")
    return account


def deposit(
    db: Session, user: User, account_number: str, amount: Decimal, description: str | None
) -> Transaction:
    if amount <= Decimal("0"):
        raise InvalidTransactionError("Amount must be positive")
    account = _own_active_account(db, user, account_number)
    account.balance = account.balance + amount
    txn = Transaction(
        amount=amount,
        transaction_type=TransactionType.DEPOSIT,
        description=description,
        status=TransactionStatus.SUCCESS,
        destination_account=account.account_number,
        account_id=account.id,
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)
    return txn


def withdraw(
    db: Session, user: User, account_number: str, amount: Decimal, description: str | None
) -> Transaction:
    if amount <= Decimal("0"):
        raise InvalidTransactionError("Amount must be positive")
    account = _own_active_account(db, user, account_number)
    if account.balance < amount:
        raise InsufficientBalanceError("Insufficient balance")
    account.balance = account.balance - amount
    txn = Transaction(
        amount=amount,
        transaction_type=TransactionType.WITHDRAWAL,
        description=description,
        status=TransactionStatus.SUCCESS,
        source_account=account.account_number,
        account_id=account.id,
    )
    db.add(txn)
    db.commit()
    db.refresh(txn)
    return txn


def transfer(
    db: Session,
    user: User,
    source_number: str,
    destination_number: str,
    amount: Decimal,
    description: str | None,
) -> tuple[Transaction, Transaction]:
    if amount <= Decimal("0"):
        raise InvalidTransactionError("Amount must be positive")
    if source_number == destination_number:
        raise InvalidTransactionError("Source and destination must differ")

    source = _own_active_account(db, user, source_number)
    destination = account_repo.get_by_number_for_update(db, destination_number)
    if destination is None:
        raise NotFoundError("Destination account not found")
    if destination.status != AccountStatus.ACTIVE:
        raise InvalidTransactionError("Destination account is not active")
    if source.currency != destination.currency:
        raise InvalidTransactionError("Currency mismatch")
    if source.balance < amount:
        raise InsufficientBalanceError("Insufficient balance")

    source.balance = source.balance - amount
    destination.balance = destination.balance + amount

    out_txn = Transaction(
        amount=amount,
        transaction_type=TransactionType.TRANSFER,
        description=description,
        status=TransactionStatus.SUCCESS,
        source_account=source.account_number,
        destination_account=destination.account_number,
        account_id=source.id,
    )
    in_txn = Transaction(
        amount=amount,
        transaction_type=TransactionType.TRANSFER,
        description=description,
        status=TransactionStatus.SUCCESS,
        source_account=source.account_number,
        destination_account=destination.account_number,
        account_id=destination.id,
    )
    db.add_all([out_txn, in_txn])
    db.commit()
    db.refresh(out_txn)
    db.refresh(in_txn)
    return out_txn, in_txn


def list_for_account(
    db: Session, user: User, account_number: str
) -> list[Transaction]:
    account = account_repo.get_by_number(db, account_number)
    if account is None or account.user_id != user.id:
        raise NotFoundError("Account not found")
    return sorted(account.transactions, key=lambda t: t.transaction_date, reverse=True)
