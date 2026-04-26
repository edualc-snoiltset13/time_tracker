from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.enums import TransactionStatus, TransactionType


class DepositRequest(BaseModel):
    account_number: str = Field(min_length=1, max_length=15)
    amount: Decimal = Field(gt=Decimal("0"))
    description: str | None = Field(default=None, max_length=255)


class WithdrawRequest(BaseModel):
    account_number: str = Field(min_length=1, max_length=15)
    amount: Decimal = Field(gt=Decimal("0"))
    description: str | None = Field(default=None, max_length=255)


class TransferRequest(BaseModel):
    source_account_number: str = Field(min_length=1, max_length=15)
    destination_account_number: str = Field(min_length=1, max_length=15)
    amount: Decimal = Field(gt=Decimal("0"))
    description: str | None = Field(default=None, max_length=255)


class TransactionDTO(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    amount: Decimal
    transaction_type: TransactionType
    transaction_date: datetime
    description: str | None
    status: TransactionStatus
    source_account: str | None
    destination_account: str | None
