"""
Stress test: concurrent transfers must not corrupt total balance.

Run against a live server:
    BANK_JWT_SECRET=testsecret1234567890123456789012 uvicorn app.main:app --port 8090 &
    python tests/stress_test_transfers.py

Pass criterion: sum of all account balances equals the starting total after
every concurrent transfer settles.
"""
import threading
import statistics
from decimal import Decimal

import httpx

BASE = "http://localhost:8090"
WORKERS = 20
TRANSFERS_PER_WORKER = 10
TRANSFER_AMOUNT = "10.00"


def register_and_login(email: str, password: str = "Pass1234!") -> str:
    httpx.post(f"{BASE}/api/auth/register", json={
        "first_name": "Test", "last_name": "User",
        "email": email, "password": password,
    }, timeout=10).raise_for_status()
    r = httpx.post(f"{BASE}/api/auth/login",
                   json={"email": email, "password": password}, timeout=10)
    r.raise_for_status()
    return r.json()["token"]


def open_account(token: str, deposit: str) -> str:
    headers = {"Authorization": f"Bearer {token}"}
    r = httpx.post(f"{BASE}/api/accounts", json={
        "account_type": "SAVINGS", "currency": "USD",
    }, headers=headers, timeout=10)
    r.raise_for_status()
    number = r.json()["data"]["account_number"]
    httpx.post(f"{BASE}/api/transactions/deposit", json={
        "account_number": number, "amount": deposit,
    }, headers=headers, timeout=10).raise_for_status()
    return number


def get_balance(token: str, account_number: str) -> Decimal:
    r = httpx.get(f"{BASE}/api/accounts/{account_number}",
                  headers={"Authorization": f"Bearer {token}"}, timeout=10)
    r.raise_for_status()
    return Decimal(str(r.json()["data"]["balance"]))


def do_transfers(token: str, src: str, dst: str,
                 n: int, errors: list) -> None:
    headers = {"Authorization": f"Bearer {token}"}
    for _ in range(n):
        r = httpx.post(f"{BASE}/api/transactions/transfer", json={
            "source_account_number": src,
            "destination_account_number": dst,
            "amount": TRANSFER_AMOUNT,
        }, headers=headers, timeout=10)
        if r.status_code not in (200, 201, 400):  # 400 = insufficient, ok
            errors.append(f"HTTP {r.status_code}: {r.text}")


def main() -> None:
    print(f"Registering {WORKERS} users and opening accounts...")
    users = []
    initial_total = Decimal("0")
    seed = str(Decimal(TRANSFER_AMOUNT) * TRANSFERS_PER_WORKER * 2)

    for i in range(WORKERS):
        email = f"stress{i}@test.local"
        token = register_and_login(email)
        src = open_account(token, seed)
        dst = open_account(token, seed)
        initial_total += Decimal(seed) * 2
        users.append((token, src, dst))

    print(f"Initial total balance: {initial_total}")
    print(f"Launching {WORKERS} workers × {TRANSFERS_PER_WORKER} transfers...")

    errors: list[str] = []
    threads = [
        threading.Thread(
            target=do_transfers,
            args=(token, src, dst, TRANSFERS_PER_WORKER, errors),
            daemon=True,
        )
        for token, src, dst in users
    ]

    # Also add cross-user transfers to create genuine contention
    for i in range(WORKERS):
        t_a, src_a, _ = users[i]
        _, _, dst_b = users[(i + 1) % WORKERS]
        threads.append(threading.Thread(
            target=do_transfers,
            args=(t_a, src_a, dst_b, TRANSFERS_PER_WORKER // 2, errors),
            daemon=True,
        ))

    barrier = threading.Barrier(len(threads))

    def run(fn, *args):
        barrier.wait()  # all threads start simultaneously
        fn(*args)

    real_threads = [
        threading.Thread(target=run, args=(t._target, *t._args), daemon=True)
        for t in threads
    ]
    for t in real_threads:
        t.start()
    for t in real_threads:
        t.join(timeout=60)

    print("All threads finished. Checking balances...")

    final_total = Decimal("0")
    for token, src, dst in users:
        final_total += get_balance(token, src) + get_balance(token, dst)

    print(f"Final total balance:   {final_total}")

    if errors:
        print(f"\nUnexpected HTTP errors ({len(errors)}):")
        for e in errors[:10]:
            print(f"  {e}")

    if final_total == initial_total:
        print("\n✓ PASS — total balance conserved under concurrency")
    else:
        diff = final_total - initial_total
        print(f"\n✗ FAIL — balance mismatch: {diff:+} (race condition detected!)")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
