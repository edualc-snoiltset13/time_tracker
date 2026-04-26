from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.account import Account
from app.models.transaction import Transaction


def list_by_account_number(db: Session, account_number: str) -> list[Transaction]:
    stmt = (
        select(Transaction)
        .join(Account, Transaction.account_id == Account.id)
        .where(Account.account_number == account_number)
        .order_by(Transaction.transaction_date.desc())
    )
    return list(db.execute(stmt).scalars())


def add(db: Session, txn: Transaction) -> Transaction:
    db.add(txn)
    return txn
