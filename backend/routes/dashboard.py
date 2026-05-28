"""Dashboard analytics routes for the sales tracking dashboard."""

from datetime import datetime, timedelta, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func

from extensions import db
from models import Sale, SaleItem, Product, User

dashboard_bp = Blueprint("dashboard", __name__, url_prefix="/api/dashboard")


@dashboard_bp.route("/summary", methods=["GET"])
@jwt_required()
def summary():
    """Return high-level KPIs: total revenue, sales count, product count, low stock."""
    user = User.query.get(get_jwt_identity())

    sale_query = db.session.query(func.count(Sale.id), func.coalesce(func.sum(Sale.total_amount), 0))
    if user.role != "admin":
        sale_query = sale_query.filter(Sale.agent_id == user.id)
    sales_count, total_revenue = sale_query.one()

    product_count = Product.query.count()
    low_stock_count = Product.query.filter(Product.quantity < 10).count()

    return jsonify({
        "total_revenue": round(float(total_revenue), 2),
        "sales_count": sales_count,
        "product_count": product_count,
        "low_stock_count": low_stock_count,
    }), 200


@dashboard_bp.route("/sales-over-time", methods=["GET"])
@jwt_required()
def sales_over_time():
    """Return daily sales totals for the last N days (default 30)."""
    days = request.args.get("days", 30, type=int)
    user = User.query.get(get_jwt_identity())
    since = datetime.now(timezone.utc) - timedelta(days=days)

    query = (
        db.session.query(
            func.date(Sale.created_at).label("date"),
            func.sum(Sale.total_amount).label("revenue"),
            func.count(Sale.id).label("count"),
        )
        .filter(Sale.created_at >= since)
    )
    if user.role != "admin":
        query = query.filter(Sale.agent_id == user.id)

    rows = query.group_by(func.date(Sale.created_at)).order_by(func.date(Sale.created_at)).all()

    return jsonify({
        "data": [
            {"date": str(row.date), "revenue": round(float(row.revenue), 2), "count": row.count}
            for row in rows
        ]
    }), 200


@dashboard_bp.route("/top-products", methods=["GET"])
@jwt_required()
def top_products():
    """Return top-selling products by quantity sold."""
    limit = request.args.get("limit", 10, type=int)

    rows = (
        db.session.query(
            Product.name,
            func.sum(SaleItem.quantity).label("total_sold"),
            func.sum(SaleItem.subtotal).label("total_revenue"),
        )
        .join(SaleItem, SaleItem.product_id == Product.id)
        .group_by(Product.id, Product.name)
        .order_by(func.sum(SaleItem.quantity).desc())
        .limit(limit)
        .all()
    )

    return jsonify({
        "data": [
            {"name": row.name, "total_sold": int(row.total_sold), "total_revenue": round(float(row.total_revenue), 2)}
            for row in rows
        ]
    }), 200


@dashboard_bp.route("/sales-by-agent", methods=["GET"])
@jwt_required()
def sales_by_agent():
    """Return sales breakdown per agent (admin only sees all, agents see themselves)."""
    user = User.query.get(get_jwt_identity())

    query = (
        db.session.query(
            User.username,
            func.count(Sale.id).label("sale_count"),
            func.coalesce(func.sum(Sale.total_amount), 0).label("total_revenue"),
        )
        .join(Sale, Sale.agent_id == User.id)
        .group_by(User.id, User.username)
    )

    if user.role != "admin":
        query = query.filter(User.id == user.id)

    rows = query.order_by(func.sum(Sale.total_amount).desc()).all()

    return jsonify({
        "data": [
            {"agent": row.username, "sale_count": row.sale_count, "total_revenue": round(float(row.total_revenue), 2)}
            for row in rows
        ]
    }), 200
