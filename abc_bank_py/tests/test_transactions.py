from decimal import Decimal


def _open_account(client, headers, currency="USD", account_type="SAVINGS") -> str:
    r = client.post(
        "/api/accounts",
        headers=headers,
        json={"account_type": account_type, "currency": currency},
    )
    assert r.status_code == 201
    return r.json()["account_number"]


def test_deposit_increases_balance(client, auth_headers):
    number = _open_account(client, auth_headers)
    r = client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": number, "amount": "100.00"},
    )
    assert r.status_code == 201
    r = client.get(f"/api/accounts/{number}", headers=auth_headers)
    assert Decimal(r.json()["balance"]) == Decimal("100.00")


def test_withdraw_decreases_balance(client, auth_headers):
    number = _open_account(client, auth_headers)
    client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": number, "amount": "50.00"},
    )
    r = client.post(
        "/api/transactions/withdraw",
        headers=auth_headers,
        json={"account_number": number, "amount": "20.00"},
    )
    assert r.status_code == 201
    r = client.get(f"/api/accounts/{number}", headers=auth_headers)
    assert Decimal(r.json()["balance"]) == Decimal("30.00")


def test_overdraft_rejected(client, auth_headers):
    number = _open_account(client, auth_headers)
    r = client.post(
        "/api/transactions/withdraw",
        headers=auth_headers,
        json={"account_number": number, "amount": "1.00"},
    )
    assert r.status_code == 400
    assert r.json()["detail"] == "Insufficient balance"


def test_transfer_between_two_accounts(client, auth_headers):
    a = _open_account(client, auth_headers)
    b = _open_account(client, auth_headers)
    client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": a, "amount": "100.00"},
    )
    r = client.post(
        "/api/transactions/transfer",
        headers=auth_headers,
        json={
            "source_account_number": a,
            "destination_account_number": b,
            "amount": "40.00",
        },
    )
    assert r.status_code == 201

    bal_a = Decimal(client.get(f"/api/accounts/{a}", headers=auth_headers).json()["balance"])
    bal_b = Decimal(client.get(f"/api/accounts/{b}", headers=auth_headers).json()["balance"])
    assert bal_a == Decimal("60.00")
    assert bal_b == Decimal("40.00")


def test_transfer_currency_mismatch_rejected(client, auth_headers):
    a = _open_account(client, auth_headers, currency="USD")
    b = _open_account(client, auth_headers, currency="EUR")
    client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": a, "amount": "100.00"},
    )
    r = client.post(
        "/api/transactions/transfer",
        headers=auth_headers,
        json={
            "source_account_number": a,
            "destination_account_number": b,
            "amount": "10.00",
        },
    )
    assert r.status_code == 400


def test_list_transactions(client, auth_headers):
    number = _open_account(client, auth_headers)
    client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": number, "amount": "5.00"},
    )
    client.post(
        "/api/transactions/deposit",
        headers=auth_headers,
        json={"account_number": number, "amount": "7.00"},
    )
    r = client.get(f"/api/accounts/{number}/transactions", headers=auth_headers)
    assert r.status_code == 200
    assert len(r.json()) == 2
