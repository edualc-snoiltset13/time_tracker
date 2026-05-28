"""Tests for sales routes."""

from models import Product
from extensions import db as _db


def _create_product(app):
    """Helper to create a product inside the app context."""
    with app.app_context():
        p = Product(name="Sale Item", sku="SI-001", price=10.0, quantity=50, category="Test")
        _db.session.add(p)
        _db.session.commit()
        return p.id


def test_create_sale_success(client, app, agent_token):
    pid = _create_product(app)
    resp = client.post("/api/sales", json={
        "items": [{"product_id": pid, "quantity": 3}]
    }, headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 201
    sale = resp.get_json()["sale"]
    assert sale["total_amount"] == 30.0
    assert len(sale["items"]) == 1
    assert sale["items"][0]["quantity"] == 3


def test_create_sale_insufficient_stock(client, app, agent_token):
    pid = _create_product(app)
    resp = client.post("/api/sales", json={
        "items": [{"product_id": pid, "quantity": 999}]
    }, headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 400
    assert "Insufficient stock" in resp.get_json()["error"]


def test_create_sale_product_not_found(client, agent_token):
    resp = client.post("/api/sales", json={
        "items": [{"product_id": 9999, "quantity": 1}]
    }, headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 404


def test_create_sale_empty_items(client, agent_token):
    resp = client.post("/api/sales", json={
        "items": []
    }, headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 400


def test_create_sale_no_auth(client):
    resp = client.post("/api/sales", json={"items": [{"product_id": 1, "quantity": 1}]})
    assert resp.status_code == 401


def test_list_sales_agent_sees_own(client, app, agent_token, admin_token):
    pid = _create_product(app)

    # Agent creates a sale
    client.post("/api/sales", json={
        "items": [{"product_id": pid, "quantity": 1}]
    }, headers={"Authorization": f"Bearer {agent_token}"})

    # Agent sees their sale
    resp = client.get("/api/sales", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    assert resp.get_json()["total"] == 1

    # Admin also sees the sale
    resp = client.get("/api/sales", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.get_json()["total"] == 1


def test_get_sale_detail(client, app, agent_token):
    pid = _create_product(app)
    create_resp = client.post("/api/sales", json={
        "items": [{"product_id": pid, "quantity": 2}]
    }, headers={"Authorization": f"Bearer {agent_token}"})
    sale_id = create_resp.get_json()["sale"]["id"]

    resp = client.get(f"/api/sales/{sale_id}", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    assert resp.get_json()["sale"]["id"] == sale_id


def test_get_sale_not_found(client, agent_token):
    resp = client.get("/api/sales/9999", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 404


def test_inventory_decremented_after_sale(client, app, agent_token):
    pid = _create_product(app)
    client.post("/api/sales", json={
        "items": [{"product_id": pid, "quantity": 5}]
    }, headers={"Authorization": f"Bearer {agent_token}"})

    resp = client.get(f"/api/products/{pid}", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.get_json()["product"]["quantity"] == 45  # 50 - 5
