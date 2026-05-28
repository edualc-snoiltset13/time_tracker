"""Shared pytest fixtures for backend tests."""

import sys
import os
import pytest

# Ensure the backend package is importable
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app import create_app
from config import TestingConfig
from extensions import db as _db
from models import User, Product


@pytest.fixture(scope="function")
def app():
    """Create a fresh Flask app for each test."""
    app = create_app(TestingConfig)
    with app.app_context():
        _db.create_all()
        yield app
        _db.session.remove()
        _db.drop_all()


@pytest.fixture
def client(app):
    """Flask test client."""
    return app.test_client()


@pytest.fixture
def db(app):
    """Database session scoped to each test."""
    return _db


@pytest.fixture
def admin_user(app, db):
    """Create and return an admin user."""
    user = User(username="admin", email="admin@test.com", role="admin")
    user.set_password("password123")
    db.session.add(user)
    db.session.commit()
    return user


@pytest.fixture
def agent_user(app, db):
    """Create and return a sales agent user."""
    user = User(username="agent", email="agent@test.com", role="sales_agent")
    user.set_password("password123")
    db.session.add(user)
    db.session.commit()
    return user


@pytest.fixture
def admin_token(client, admin_user):
    """JWT token for the admin user."""
    resp = client.post("/api/auth/login", json={"username": "admin", "password": "password123"})
    return resp.get_json()["token"]


@pytest.fixture
def agent_token(client, agent_user):
    """JWT token for the sales agent user."""
    resp = client.post("/api/auth/login", json={"username": "agent", "password": "password123"})
    return resp.get_json()["token"]


@pytest.fixture
def sample_product(app, db):
    """Create and return a sample product."""
    product = Product(name="Test Widget", sku="TW-001", price=19.99, quantity=100, category="Test")
    db.session.add(product)
    db.session.commit()
    return product
