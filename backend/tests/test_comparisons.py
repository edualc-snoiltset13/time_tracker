"""Tests for data comparison routes."""

from datetime import datetime, timedelta, timezone
from models import Product, Sale, SaleItem, User
from extensions import db as _db


def _seed_comparison_data(app, admin_id):
    """Create two products, two agents, and several sales for comparison tests."""
    with app.app_context():
        p1 = Product(name="Alpha Widget", sku="AW-001", price=10.0, quantity=100, category="Electronics")
        p2 = Product(name="Beta Gadget", sku="BG-002", price=25.0, quantity=50, category="Accessories")
        _db.session.add_all([p1, p2])
        _db.session.flush()

        # Sale by admin (current period)
        s1 = Sale(agent_id=admin_id, total_amount=45.0)
        s1.items.append(SaleItem(product_id=p1.id, quantity=2, unit_price=10.0, subtotal=20.0))
        s1.items.append(SaleItem(product_id=p2.id, quantity=1, unit_price=25.0, subtotal=25.0))
        p1.quantity -= 2
        p2.quantity -= 1

        # A second sale
        s2 = Sale(agent_id=admin_id, total_amount=50.0)
        s2.items.append(SaleItem(product_id=p2.id, quantity=2, unit_price=25.0, subtotal=50.0))
        p2.quantity -= 2

        _db.session.add_all([s1, s2])
        _db.session.commit()
        return p1.id, p2.id


def _seed_agent_data(app, db):
    """Create a second agent with sales for agent comparison tests."""
    with app.app_context():
        agent2 = User(username="agent2", email="agent2@test.com", role="sales_agent")
        agent2.set_password("password123")
        db.session.add(agent2)
        db.session.flush()

        p = Product(name="Gamma Item", sku="GI-003", price=15.0, quantity=80, category="Electronics")
        db.session.add(p)
        db.session.flush()

        s = Sale(agent_id=agent2.id, total_amount=30.0)
        s.items.append(SaleItem(product_id=p.id, quantity=2, unit_price=15.0, subtotal=30.0))
        p.quantity -= 2
        db.session.add(s)
        db.session.commit()
        return agent2.id


# ---- Period Comparison ----

def test_period_comparison(client, app, admin_user, admin_token):
    _seed_comparison_data(app, admin_user.id)
    resp = client.get("/api/comparisons/period", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.get_json()
    assert "current" in data
    assert "previous" in data
    assert "changes" in data
    assert data["current"]["revenue"] == 95.0
    assert data["current"]["sale_count"] == 2
    assert data["current"]["units_sold"] == 5


def test_period_comparison_custom_dates(client, app, admin_user, admin_token):
    _seed_comparison_data(app, admin_user.id)
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")
    resp = client.get(
        f"/api/comparisons/period?current_start={yesterday}&current_end={today}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    data = resp.get_json()
    assert "current" in data
    assert data["current"]["start"] == yesterday


def test_period_comparison_no_auth(client):
    resp = client.get("/api/comparisons/period")
    assert resp.status_code == 401


def test_period_has_daily_breakdown(client, app, admin_user, admin_token):
    _seed_comparison_data(app, admin_user.id)
    resp = client.get("/api/comparisons/period", headers={"Authorization": f"Bearer {admin_token}"})
    data = resp.get_json()
    assert "daily" in data["current"]
    assert isinstance(data["current"]["daily"], list)


# ---- Product Comparison ----

def test_product_comparison(client, app, admin_user, admin_token):
    p1_id, p2_id = _seed_comparison_data(app, admin_user.id)
    resp = client.get(
        f"/api/comparisons/products?ids={p1_id},{p2_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    products = resp.get_json()["products"]
    assert len(products) == 2

    alpha = next(p for p in products if p["name"] == "Alpha Widget")
    beta = next(p for p in products if p["name"] == "Beta Gadget")
    assert alpha["total_sold"] == 2
    assert alpha["total_revenue"] == 20.0
    assert beta["total_sold"] == 3
    assert beta["total_revenue"] == 75.0


def test_product_comparison_insufficient_ids(client, admin_token):
    resp = client.get(
        "/api/comparisons/products?ids=1",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 400
    assert "at least 2" in resp.get_json()["error"].lower()


def test_product_comparison_bad_ids(client, admin_token):
    resp = client.get(
        "/api/comparisons/products?ids=abc,xyz",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 400


def test_product_comparison_not_found(client, admin_token):
    resp = client.get(
        "/api/comparisons/products?ids=9998,9999",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 404


def test_product_comparison_has_monthly_trend(client, app, admin_user, admin_token):
    p1_id, p2_id = _seed_comparison_data(app, admin_user.id)
    resp = client.get(
        f"/api/comparisons/products?ids={p1_id},{p2_id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    products = resp.get_json()["products"]
    for p in products:
        assert "monthly_trend" in p


# ---- Category Comparison ----

def test_category_comparison(client, app, admin_user, admin_token):
    _seed_comparison_data(app, admin_user.id)
    resp = client.get("/api/comparisons/categories", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    categories = resp.get_json()["categories"]
    assert len(categories) >= 2

    elec = next(c for c in categories if c["category"] == "Electronics")
    assert elec["total_sold"] == 2
    assert elec["product_count"] == 1
    assert elec["inventory_value"] > 0

    acc = next(c for c in categories if c["category"] == "Accessories")
    assert acc["total_sold"] == 3
    assert acc["total_revenue"] == 75.0


def test_category_comparison_no_auth(client):
    resp = client.get("/api/comparisons/categories")
    assert resp.status_code == 401


# ---- Agent Comparison ----

def test_agent_comparison_admin_sees_all(client, app, db, admin_user, admin_token):
    _seed_comparison_data(app, admin_user.id)
    _seed_agent_data(app, db)
    resp = client.get("/api/comparisons/agents", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    agents = resp.get_json()["agents"]
    assert len(agents) == 2
    for a in agents:
        assert "total_revenue" in a
        assert "avg_order_value" in a
        assert "units_sold" in a


def test_agent_comparison_agent_sees_self(client, app, db, agent_user, agent_token):
    # Agent needs at least one sale to appear in results
    with app.app_context():
        p = Product(name="Self Item", sku="SI-099", price=5.0, quantity=50, category="Test")
        db.session.add(p)
        db.session.flush()
        s = Sale(agent_id=agent_user.id, total_amount=10.0)
        s.items.append(SaleItem(product_id=p.id, quantity=2, unit_price=5.0, subtotal=10.0))
        db.session.add(s)
        db.session.commit()

    resp = client.get("/api/comparisons/agents", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    agents = resp.get_json()["agents"]
    assert len(agents) == 1
    assert agents[0]["username"] == "agent"


def test_agent_comparison_no_auth(client):
    resp = client.get("/api/comparisons/agents")
    assert resp.status_code == 401
