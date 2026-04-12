"""Tests for authentication routes."""


def test_register_success(client):
    resp = client.post("/api/auth/register", json={
        "username": "newuser",
        "email": "newuser@test.com",
        "password": "secret123",
    })
    assert resp.status_code == 201
    data = resp.get_json()
    assert "token" in data
    assert data["user"]["username"] == "newuser"
    assert data["user"]["role"] == "sales_agent"


def test_register_admin(client):
    resp = client.post("/api/auth/register", json={
        "username": "myadmin",
        "email": "myadmin@test.com",
        "password": "secret123",
        "role": "admin",
    })
    assert resp.status_code == 201
    assert resp.get_json()["user"]["role"] == "admin"


def test_register_duplicate_username(client, admin_user):
    resp = client.post("/api/auth/register", json={
        "username": "admin",
        "email": "other@test.com",
        "password": "secret123",
    })
    assert resp.status_code == 409
    assert "already exists" in resp.get_json()["error"]


def test_register_duplicate_email(client, admin_user):
    resp = client.post("/api/auth/register", json={
        "username": "other",
        "email": "admin@test.com",
        "password": "secret123",
    })
    assert resp.status_code == 409


def test_register_validation_error(client):
    resp = client.post("/api/auth/register", json={
        "username": "ab",  # too short (min 3)
        "email": "bad",
        "password": "12345",  # too short (min 6)
    })
    assert resp.status_code == 400
    errors = resp.get_json()["errors"]
    assert "username" in errors
    assert "email" in errors
    assert "password" in errors


def test_login_success(client, admin_user):
    resp = client.post("/api/auth/login", json={"username": "admin", "password": "password123"})
    assert resp.status_code == 200
    data = resp.get_json()
    assert "token" in data
    assert data["user"]["username"] == "admin"


def test_login_wrong_password(client, admin_user):
    resp = client.post("/api/auth/login", json={"username": "admin", "password": "wrong"})
    assert resp.status_code == 401


def test_login_nonexistent_user(client):
    resp = client.post("/api/auth/login", json={"username": "ghost", "password": "pass"})
    assert resp.status_code == 401


def test_get_profile(client, admin_token):
    resp = client.get("/api/auth/me", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.get_json()["user"]["username"] == "admin"


def test_get_profile_no_token(client):
    resp = client.get("/api/auth/me")
    assert resp.status_code == 401
