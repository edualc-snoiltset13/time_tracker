from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict

from app.enums import AccountStatus, AccountType, Currency


class CreateAccountRequest(BaseModel):
    account_type: AccountType
    currency: Currency


class AccountDTO(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    account_number: str
    balance: Decimal
    account_type: AccountType
    currency: Currency
    status: AccountStatus
    created_at: datetime
