import os
from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool


def _set_env() -> None:
    os.environ.setdefault("BANK_JWT_SECRET", "x" * 48)
    os.environ.setdefault("BANK_DB_URL", "sqlite:///:memory:")


_set_env()


@pytest.fixture()
def client() -> Iterator[TestClient]:
    # Reset modules so a fresh engine is built for every test (in-memory SQLite).
    import importlib
    import sys

    for mod in list(sys.modules):
        if mod == "app" or mod.startswith("app."):
            del sys.modules[mod]

    from app import db as db_module  # noqa: F401
    from app.db import Base, get_db
    from app.main import create_app

    test_engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(bind=test_engine, autoflush=False, expire_on_commit=False)

    importlib.import_module("app.models")
    Base.metadata.create_all(bind=test_engine)

    app = create_app()

    def _override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = _override_get_db

    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture()
def auth_headers(client: TestClient) -> dict[str, str]:
    register = client.post(
        "/api/auth/register",
        json={
            "first_name": "Ada",
            "last_name": "Lovelace",
            "email": "ada@example.com",
            "password": "correct horse battery",
        },
    )
    assert register.status_code == 201, register.text
    login = client.post(
        "/api/auth/login",
        json={"email": "ada@example.com", "password": "correct horse battery"},
    )
    assert login.status_code == 200, login.text
    return {"Authorization": f"Bearer {login.json()['token']}"}
