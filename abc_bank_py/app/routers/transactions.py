from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.user import User
from app.schemas.transaction import (
    DepositRequest,
    TransactionDTO,
    TransferRequest,
    WithdrawRequest,
)
from app.security.deps import get_current_user
from app.services import transaction_service

router = APIRouter(prefix="/api", tags=["transactions"])


@router.post(
    "/transactions/deposit",
    response_model=TransactionDTO,
    status_code=status.HTTP_201_CREATED,
)
def deposit(
    req: DepositRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> TransactionDTO:
    txn = transaction_service.deposit(db, user, req.account_number, req.amount, req.description)
    return TransactionDTO.model_validate(txn)


@router.post(
    "/transactions/withdraw",
    response_model=TransactionDTO,
    status_code=status.HTTP_201_CREATED,
)
def withdraw(
    req: WithdrawRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> TransactionDTO:
    txn = transaction_service.withdraw(db, user, req.account_number, req.amount, req.description)
    return TransactionDTO.model_validate(txn)


@router.post(
    "/transactions/transfer",
    response_model=TransactionDTO,
    status_code=status.HTTP_201_CREATED,
)
def transfer(
    req: TransferRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> TransactionDTO:
    out_txn, _ = transaction_service.transfer(
        db,
        user,
        req.source_account_number,
        req.destination_account_number,
        req.amount,
        req.description,
    )
    return TransactionDTO.model_validate(out_txn)


@router.get("/accounts/{account_number}/transactions", response_model=list[TransactionDTO])
def list_transactions(
    account_number: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[TransactionDTO]:
    txns = transaction_service.list_for_account(db, user, account_number)
    return [TransactionDTO.model_validate(t) for t in txns]
