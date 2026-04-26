# abc_bank (Python port)

A FastAPI rewrite of the `abc_bank/` Spring Boot demo. Uses SQLAlchemy 2.x, Pydantic v2, PyJWT, and bcrypt.

## Setup

```sh
cd abc_bank_py
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env
# Generate a strong JWT secret and put it in .env:
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

## Run

```sh
uvicorn app.main:app --reload --port 8090
# OpenAPI docs: http://localhost:8090/docs
```

## Test

```sh
pytest -q
```

## Endpoints

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/healthz` | public | Liveness check |
| POST | `/api/auth/register` | public | Always assigns `CUSTOMER` role; ignores any `roles` in payload |
| POST | `/api/auth/login` | public | Returns JWT bearer token |
| POST | `/api/auth/password/reset/request` | public | Returns 202 regardless of email validity |
| POST | `/api/auth/password/reset/confirm` | public | Consumes one-time code |
| POST | `/api/auth/password/change` | bearer | |
| POST | `/api/accounts` | bearer | Open a new account |
| GET | `/api/accounts` | bearer | List own accounts |
| GET | `/api/accounts/{number}` | bearer | |
| DELETE | `/api/accounts/{number}` | bearer | Close (balance must be 0) |
| POST | `/api/transactions/deposit` | bearer | |
| POST | `/api/transactions/withdraw` | bearer | 400 on overdraft |
| POST | `/api/transactions/transfer` | bearer | Same currency only |
| GET | `/api/accounts/{number}/transactions` | bearer | |

## Differences from the Java original

The Java code is a skeleton (entities + JWT scaffolding, no controllers or services). This port adds the missing business logic and fixes the security issues flagged in review:

- **JWT secret** is loaded from `BANK_JWT_SECRET`. Startup fails if missing or shorter than 32 bytes.
- **Registration does not accept a `roles` field.** All new users get `CUSTOMER`. Role changes are admin-only (not exposed yet).
- **Passwords are bcrypt-hashed** (Java code stored them with the framework default, never used).
- **Login returns a uniform `401 "Invalid credentials"`** for unknown emails and bad passwords.
- **Generic 500 handler** returns `{"detail":"Internal error"}`; full stack logged server-side only.
