def test_create_and_list_account(client, auth_headers):
    r = client.post(
        "/api/accounts",
        headers=auth_headers,
        json={"account_type": "SAVINGS", "currency": "USD"},
    )
    assert r.status_code == 201
    body = r.json()
    assert body["account_type"] == "SAVINGS"
    assert body["currency"] == "USD"
    assert body["status"] == "ACTIVE"
    assert len(body["account_number"]) == 15
    number = body["account_number"]

    r = client.get("/api/accounts", headers=auth_headers)
    assert r.status_code == 200
    assert any(a["account_number"] == number for a in r.json())

    r = client.get(f"/api/accounts/{number}", headers=auth_headers)
    assert r.status_code == 200


def test_account_requires_auth(client):
    r = client.post("/api/accounts", json={"account_type": "SAVINGS", "currency": "USD"})
    assert r.status_code == 401


def test_close_zero_balance(client, auth_headers):
    r = client.post(
        "/api/accounts",
        headers=auth_headers,
        json={"account_type": "CURRENT", "currency": "EUR"},
    )
    number = r.json()["account_number"]
    r = client.delete(f"/api/accounts/{number}", headers=auth_headers)
    assert r.status_code == 200
    assert r.json()["status"] == "CLOSED"


def test_other_user_cannot_see_account(client):
    # User A creates an account
    client.post(
        "/api/auth/register",
        json={
            "first_name": "A",
            "last_name": "A",
            "email": "a@example.com",
            "password": "passpasspass",
        },
    )
    a_token = client.post(
        "/api/auth/login",
        json={"email": "a@example.com", "password": "passpasspass"},
    ).json()["token"]
    a_headers = {"Authorization": f"Bearer {a_token}"}
    number = client.post(
        "/api/accounts",
        headers=a_headers,
        json={"account_type": "SAVINGS", "currency": "USD"},
    ).json()["account_number"]

    # User B tries to access it
    client.post(
        "/api/auth/register",
        json={
            "first_name": "B",
            "last_name": "B",
            "email": "b@example.com",
            "password": "passpasspass",
        },
    )
    b_token = client.post(
        "/api/auth/login",
        json={"email": "b@example.com", "password": "passpasspass"},
    ).json()["token"]
    b_headers = {"Authorization": f"Bearer {b_token}"}

    r = client.get(f"/api/accounts/{number}", headers=b_headers)
    assert r.status_code == 404
