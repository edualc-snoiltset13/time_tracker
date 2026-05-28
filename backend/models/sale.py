"""Sale and SaleItem models for tracking transactions."""

from datetime import datetime, timezone
from extensions import db


class Sale(db.Model):
    __tablename__ = "sales"

    id = db.Column(db.Integer, primary_key=True)
    agent_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    total_amount = db.Column(db.Float, nullable=False, default=0.0)
    status = db.Column(db.String(20), default="completed")  # completed | refunded
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    items = db.relationship("SaleItem", backref="sale", lazy="joined", cascade="all, delete-orphan")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "agent_id": self.agent_id,
            "agent_name": self.agent.username if self.agent else None,
            "total_amount": self.total_amount,
            "status": self.status,
            "items": [item.to_dict() for item in self.items],
            "created_at": self.created_at.isoformat(),
        }


class SaleItem(db.Model):
    __tablename__ = "sale_items"

    id = db.Column(db.Integer, primary_key=True)
    sale_id = db.Column(db.Integer, db.ForeignKey("sales.id"), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey("products.id"), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Float, nullable=False)
    subtotal = db.Column(db.Float, nullable=False)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "product_id": self.product_id,
            "product_name": self.product.name if self.product else None,
            "quantity": self.quantity,
            "unit_price": self.unit_price,
            "subtotal": self.subtotal,
        }
