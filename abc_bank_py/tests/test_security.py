import os

import pytest


def test_jwt_secret_required(monkeypatch):
    monkeypatch.delenv("BANK_JWT_SECRET", raising=False)
    monkeypatch.setattr("app.config.SettingsConfigDict", None, raising=False)

    import importlib
    import sys

    for mod in list(sys.modules):
        if mod == "app" or mod.startswith("app."):
            del sys.modules[mod]

    with pytest.raises(Exception):
        importlib.import_module("app.config").Settings()  # type: ignore[call-arg]

    os.environ["BANK_JWT_SECRET"] = "x" * 48


def test_jwt_secret_too_short_rejected(monkeypatch):
    monkeypatch.setenv("BANK_JWT_SECRET", "short")

    import importlib
    import sys

    for mod in list(sys.modules):
        if mod == "app" or mod.startswith("app."):
            del sys.modules[mod]

    with pytest.raises(Exception):
        importlib.import_module("app.config").Settings()  # type: ignore[call-arg]

    monkeypatch.setenv("BANK_JWT_SECRET", "x" * 48)


def test_authenticated_endpoint_rejects_missing_token(client):
    r = client.get("/api/accounts")
    assert r.status_code == 401


def test_authenticated_endpoint_rejects_garbage_token(client):
    r = client.get("/api/accounts", headers={"Authorization": "Bearer not-a-jwt"})
    assert r.status_code == 401
