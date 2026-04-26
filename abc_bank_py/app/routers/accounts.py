from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.user import User
from app.schemas.account import AccountDTO, CreateAccountRequest
from app.security.deps import get_current_user
from app.services import account_service

router = APIRouter(prefix="/api/accounts", tags=["accounts"])


@router.post("", response_model=AccountDTO, status_code=status.HTTP_201_CREATED)
def create_account(
    req: CreateAccountRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> AccountDTO:
    account = account_service.create_account(db, user, req)
    return AccountDTO.model_validate(account)


@router.get("", response_model=list[AccountDTO])
def list_accounts(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[AccountDTO]:
    return [AccountDTO.model_validate(a) for a in account_service.list_for_user(db, user)]


@router.get("/{account_number}", response_model=AccountDTO)
def get_account(
    account_number: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> AccountDTO:
    return AccountDTO.model_validate(account_service.get_for_user(db, user, account_number))


@router.delete("/{account_number}", response_model=AccountDTO)
def close_account(
    account_number: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> AccountDTO:
    return AccountDTO.model_validate(account_service.close_for_user(db, user, account_number))
