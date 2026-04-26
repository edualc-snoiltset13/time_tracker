from datetime import datetime, timedelta, timezone

import jwt

from app.config import Settings


_ALGORITHM = "HS256"


def generate_token(subject: str, settings: Settings) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": subject,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=settings.jwt_ttl_seconds)).timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=_ALGORITHM)


def decode_token(token: str, settings: Settings) -> dict:
    return jwt.decode(token, settings.jwt_secret, algorithms=[_ALGORITHM])


def subject_from_token(token: str, settings: Settings) -> str:
    payload = decode_token(token, settings)
    sub = payload.get("sub")
    if not isinstance(sub, str) or not sub:
        raise jwt.InvalidTokenError("missing subject")
    return sub
