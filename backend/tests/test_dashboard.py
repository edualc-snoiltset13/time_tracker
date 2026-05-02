"""Tests for dashboard analytics routes."""

from models import Product, Sale, SaleItem
from extensions import db as _db


def _seed_sale(app, agent_id):
    """Helper to insert a product and sale for dashboard tests."""
    with app.app_context():
        p = Product(name="Dash Item", sku="DI-001", price=25.0, quantity=100, category="Test")
        _db.session.add(p)
        _db.session.flush()

        sale = Sale(agent_id=agent_id, total_amount=50.0)
        item = SaleItem(product_id=p.id, quantity=2, unit_price=25.0, subtotal=50.0)
        sale.items.append(item)
        p.quantity -= 2
        _db.session.add(sale)
        _db.session.commit()


def test_summary(client, app, agent_user, agent_token):
    _seed_sale(app, agent_user.id)
    resp = client.get("/api/dashboard/summary", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    data = resp.get_json()
    assert data["total_revenue"] == 50.0
    assert data["sales_count"] == 1
    assert data["product_count"] == 1


def test_summary_no_auth(client):
    resp = client.get("/api/dashboard/summary")
    assert resp.status_code == 401


def test_sales_over_time(client, app, agent_user, agent_token):
    _seed_sale(app, agent_user.id)
    resp = client.get("/api/dashboard/sales-over-time", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    data = resp.get_json()["data"]
    assert len(data) >= 1
    assert data[0]["revenue"] == 50.0


def test_top_products(client, app, agent_user, agent_token):
    _seed_sale(app, agent_user.id)
    resp = client.get("/api/dashboard/top-products", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    data = resp.get_json()["data"]
    assert len(data) == 1
    assert data[0]["name"] == "Dash Item"
    assert data[0]["total_sold"] == 2


def test_sales_by_agent(client, app, admin_user, admin_token):
    _seed_sale(app, admin_user.id)
    resp = client.get("/api/dashboard/sales-by-agent", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.get_json()["data"]
    assert len(data) == 1
    assert data[0]["agent"] == "admin"
