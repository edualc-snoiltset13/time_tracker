"""Tests for product CRUD routes."""


def test_list_products_empty(client, agent_token):
    resp = client.get("/api/products", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 200
    assert resp.get_json()["products"] == []
    assert resp.get_json()["total"] == 0


def test_create_product_admin(client, admin_token):
    resp = client.post("/api/products", json={
        "name": "Widget",
        "sku": "WG-001",
        "price": 9.99,
        "quantity": 50,
        "category": "Gadgets",
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 201
    product = resp.get_json()["product"]
    assert product["name"] == "Widget"
    assert product["sku"] == "WG-001"


def test_create_product_agent_forbidden(client, agent_token):
    resp = client.post("/api/products", json={
        "name": "Widget",
        "sku": "WG-001",
        "price": 9.99,
        "quantity": 50,
    }, headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 403


def test_create_product_duplicate_sku(client, admin_token, sample_product):
    resp = client.post("/api/products", json={
        "name": "Another",
        "sku": "TW-001",  # same as sample_product
        "price": 5.0,
        "quantity": 10,
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 409


def test_create_product_validation_error(client, admin_token):
    resp = client.post("/api/products", json={
        "name": "",
        "sku": "",
        "price": -5,
        "quantity": -1,
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 400


def test_get_product(client, agent_token, sample_product):
    resp = client.get(
        f"/api/products/{sample_product.id}",
        headers={"Authorization": f"Bearer {agent_token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["product"]["sku"] == "TW-001"


def test_get_product_not_found(client, agent_token):
    resp = client.get("/api/products/999", headers={"Authorization": f"Bearer {agent_token}"})
    assert resp.status_code == 404


def test_update_product_admin(client, admin_token, sample_product):
    resp = client.put(
        f"/api/products/{sample_product.id}",
        json={"price": 24.99, "quantity": 200},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    product = resp.get_json()["product"]
    assert product["price"] == 24.99
    assert product["quantity"] == 200


def test_update_product_agent_forbidden(client, agent_token, sample_product):
    resp = client.put(
        f"/api/products/{sample_product.id}",
        json={"price": 1.0},
        headers={"Authorization": f"Bearer {agent_token}"},
    )
    assert resp.status_code == 403


def test_delete_product_admin(client, admin_token, sample_product):
    resp = client.delete(
        f"/api/products/{sample_product.id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200

    # Verify it's gone
    resp = client.get(
        f"/api/products/{sample_product.id}",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 404


def test_delete_product_agent_forbidden(client, agent_token, sample_product):
    resp = client.delete(
        f"/api/products/{sample_product.id}",
        headers={"Authorization": f"Bearer {agent_token}"},
    )
    assert resp.status_code == 403


def test_list_products_search(client, admin_token, sample_product):
    resp = client.get(
        "/api/products?search=Widget",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["total"] == 1


def test_list_products_category_filter(client, admin_token, sample_product):
    resp = client.get(
        "/api/products?category=Test",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.get_json()["total"] == 1


def test_list_categories(client, admin_token, sample_product):
    resp = client.get("/api/products/categories", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert "Test" in resp.get_json()["categories"]
