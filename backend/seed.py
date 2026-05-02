"""Seed the database with sample data for development."""

from app import create_app
from extensions import db
from models import User, Product, Sale, SaleItem

app = create_app()

SAMPLE_PRODUCTS = [
    {"name": "Wireless Mouse", "sku": "WM-001", "price": 29.99, "quantity": 150, "category": "Electronics"},
    {"name": "Mechanical Keyboard", "sku": "MK-002", "price": 89.99, "quantity": 75, "category": "Electronics"},
    {"name": "USB-C Hub", "sku": "UH-003", "price": 49.99, "quantity": 200, "category": "Electronics"},
    {"name": "Monitor Stand", "sku": "MS-004", "price": 39.99, "quantity": 60, "category": "Accessories"},
    {"name": "Desk Lamp", "sku": "DL-005", "price": 24.99, "quantity": 120, "category": "Accessories"},
    {"name": "Webcam HD", "sku": "WC-006", "price": 59.99, "quantity": 90, "category": "Electronics"},
    {"name": "Headset Pro", "sku": "HP-007", "price": 79.99, "quantity": 45, "category": "Audio"},
    {"name": "Mouse Pad XL", "sku": "MP-008", "price": 14.99, "quantity": 300, "category": "Accessories"},
    {"name": "Laptop Stand", "sku": "LS-009", "price": 34.99, "quantity": 8, "category": "Accessories"},
    {"name": "Bluetooth Speaker", "sku": "BS-010", "price": 44.99, "quantity": 5, "category": "Audio"},
]

with app.app_context():
    db.drop_all()
    db.create_all()

    # Create users
    admin = User(username="admin", email="admin@example.com", role="admin")
    admin.set_password("admin123")

    agent1 = User(username="alice", email="alice@example.com", role="sales_agent")
    agent1.set_password("alice123")

    agent2 = User(username="bob", email="bob@example.com", role="sales_agent")
    agent2.set_password("bob123")

    db.session.add_all([admin, agent1, agent2])
    db.session.flush()

    # Create products
    products = []
    for p in SAMPLE_PRODUCTS:
        product = Product(**p)
        products.append(product)
        db.session.add(product)
    db.session.flush()

    # Create sample sales
    sample_sales = [
        {"agent": agent1, "items": [(products[0], 2), (products[1], 1)]},
        {"agent": agent1, "items": [(products[2], 3), (products[4], 2)]},
        {"agent": agent2, "items": [(products[5], 1), (products[6], 1)]},
        {"agent": agent2, "items": [(products[3], 2), (products[7], 5)]},
        {"agent": agent1, "items": [(products[8], 1), (products[9], 2)]},
    ]

    for sale_data in sample_sales:
        sale = Sale(agent_id=sale_data["agent"].id)
        total = 0.0
        for product, qty in sale_data["items"]:
            subtotal = product.price * qty
            item = SaleItem(
                product_id=product.id,
                quantity=qty,
                unit_price=product.price,
                subtotal=subtotal,
            )
            sale.items.append(item)
            product.quantity -= qty
            total += subtotal
        sale.total_amount = round(total, 2)
        db.session.add(sale)

    db.session.commit()
    print("Database seeded successfully!")
    print(f"  Users: {User.query.count()}")
    print(f"  Products: {Product.query.count()}")
    print(f"  Sales: {Sale.query.count()}")
