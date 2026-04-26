def test_register_and_login(client):
    r = client.post(
        "/api/auth/register",
        json={
            "first_name": "Grace",
            "last_name": "Hopper",
            "email": "grace@example.com",
            "password": "supersecret123",
        },
    )
    assert r.status_code == 201
    body = r.json()
    assert body["email"] == "grace@example.com"
    assert body["roles"] == ["CUSTOMER"]

    r = client.post(
        "/api/auth/login",
        json={"email": "grace@example.com", "password": "supersecret123"},
    )
    assert r.status_code == 200
    assert "token" in r.json()
    assert r.json()["roles"] == ["CUSTOMER"]


def test_register_rejects_extra_roles_field(client):
    """The Java DTO had a `roles` field exploitable for privilege escalation.

    The Python schema must not honour client-supplied roles; pydantic ignores extra
    fields by default. Even if `roles` is supplied, the server assigns CUSTOMER.
    """
    r = client.post(
        "/api/auth/register",
        json={
            "first_name": "Eve",
            "last_name": "Attacker",
            "email": "eve@example.com",
            "password": "supersecret123",
            "roles": ["ADMIN"],
        },
    )
    assert r.status_code == 201
    assert r.json()["roles"] == ["CUSTOMER"]


def test_duplicate_email_rejected(client):
    payload = {
        "first_name": "A",
        "last_name": "B",
        "email": "dup@example.com",
        "password": "password1234",
    }
    assert client.post("/api/auth/register", json=payload).status_code == 201
    r = client.post("/api/auth/register", json=payload)
    assert r.status_code == 400


def test_login_wrong_password(client):
    client.post(
        "/api/auth/register",
        json={
            "first_name": "A",
            "last_name": "B",
            "email": "user@example.com",
            "password": "password1234",
        },
    )
    r = client.post(
        "/api/auth/login",
        json={"email": "user@example.com", "password": "WRONG"},
    )
    assert r.status_code == 401


def test_login_unknown_email_uniform_error(client):
    r = client.post(
        "/api/auth/login",
        json={"email": "nope@example.com", "password": "WRONG"},
    )
    assert r.status_code == 401
    assert r.json() == {"detail": "Invalid credentials"}


def test_change_password(client, auth_headers):
    r = client.post(
        "/api/auth/password/change",
        headers=auth_headers,
        json={"old_password": "correct horse battery", "new_password": "new pass phrase!"},
    )
    assert r.status_code == 200

    # Old password should no longer work
    r = client.post(
        "/api/auth/login",
        json={"email": "ada@example.com", "password": "correct horse battery"},
    )
    assert r.status_code == 401

    # New password works
    r = client.post(
        "/api/auth/login",
        json={"email": "ada@example.com", "password": "new pass phrase!"},
    )
    assert r.status_code == 200
