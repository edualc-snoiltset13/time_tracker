from enum import StrEnum


class AccountStatus(StrEnum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    CLOSED = "CLOSED"


class AccountType(StrEnum):
    SAVINGS = "SAVINGS"
    CURRENT = "CURRENT"


class Currency(StrEnum):
    USD = "USD"
    EUR = "EUR"
    INR = "INR"


class TransactionStatus(StrEnum):
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    PENDING = "PENDING"


class TransactionType(StrEnum):
    DEPOSIT = "DEPOSIT"
    WITHDRAWAL = "WITHDRAWAL"
    TRANSFER = "TRANSFER"


class NotificationType(StrEnum):
    EMAIL = "EMAIL"
    SMS = "SMS"
    PUSH = "PUSH"


ROLE_CUSTOMER = "CUSTOMER"
ROLE_ADMIN = "ADMIN"
ROLE_AUDITOR = "AUDITOR"
