"""Data comparison routes: period-over-period, product-vs-product, category, and agent comparisons."""

from datetime import datetime, timedelta, timezone
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func, case

from extensions import db
from models import Sale, SaleItem, Product, User

comparisons_bp = Blueprint("comparisons", __name__, url_prefix="/api/comparisons")


def _parse_date(date_str, default):
    """Parse a YYYY-MM-DD string or return the default."""
    if not date_str:
        return default
    try:
        return datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    except ValueError:
        return default


def _period_stats(user, start, end):
    """Compute revenue, sale count, units sold, and avg order value for a date range."""
    sale_q = (
        db.session.query(
            func.coalesce(func.sum(Sale.total_amount), 0).label("revenue"),
            func.count(Sale.id).label("sale_count"),
        )
        .filter(Sale.created_at >= start, Sale.created_at < end)
    )
    if user.role != "admin":
        sale_q = sale_q.filter(Sale.agent_id == user.id)
    revenue, sale_count = sale_q.one()

    units_q = (
        db.session.query(func.coalesce(func.sum(SaleItem.quantity), 0))
        .join(Sale, Sale.id == SaleItem.sale_id)
        .filter(Sale.created_at >= start, Sale.created_at < end)
    )
    if user.role != "admin":
        units_q = units_q.filter(Sale.agent_id == user.id)
    units_sold = units_q.scalar()

    revenue = float(revenue)
    avg_order = round(revenue / sale_count, 2) if sale_count else 0.0

    return {
        "revenue": round(revenue, 2),
        "sale_count": sale_count,
        "units_sold": int(units_sold),
        "avg_order_value": avg_order,
    }


def _pct_change(current, previous):
    """Percentage change from previous to current; None if previous is zero."""
    if previous == 0:
        return None
    return round(((current - previous) / previous) * 100, 2)


@comparisons_bp.route("/period", methods=["GET"])
@jwt_required()
def period_comparison():
    """Compare two time periods side by side.

    Query params:
      current_start, current_end   — YYYY-MM-DD (default: last 30 days)
      previous_start, previous_end — YYYY-MM-DD (default: the 30 days before that)
    """
    user = User.query.get(get_jwt_identity())
    now = datetime.now(timezone.utc)

    current_end = _parse_date(request.args.get("current_end"), now)
    current_start = _parse_date(request.args.get("current_start"), current_end - timedelta(days=30))
    span = (current_end - current_start).days
    previous_end = _parse_date(request.args.get("previous_end"), current_start)
    previous_start = _parse_date(request.args.get("previous_start"), previous_end - timedelta(days=span))

    current = _period_stats(user, current_start, current_end)
    previous = _period_stats(user, previous_start, previous_end)

    changes = {
        "revenue": _pct_change(current["revenue"], previous["revenue"]),
        "sale_count": _pct_change(current["sale_count"], previous["sale_count"]),
        "units_sold": _pct_change(current["units_sold"], previous["units_sold"]),
        "avg_order_value": _pct_change(current["avg_order_value"], previous["avg_order_value"]),
    }

    # Daily breakdown for both periods so the frontend can overlay two line charts
    def _daily(start, end):
        q = (
            db.session.query(
                func.date(Sale.created_at).label("date"),
                func.sum(Sale.total_amount).label("revenue"),
                func.count(Sale.id).label("count"),
            )
            .filter(Sale.created_at >= start, Sale.created_at < end)
        )
        if user.role != "admin":
            q = q.filter(Sale.agent_id == user.id)
        rows = q.group_by(func.date(Sale.created_at)).order_by(func.date(Sale.created_at)).all()
        return [{"date": str(r.date), "revenue": round(float(r.revenue), 2), "count": r.count} for r in rows]

    return jsonify({
        "current": {**current, "start": current_start.strftime("%Y-%m-%d"), "end": current_end.strftime("%Y-%m-%d"), "daily": _daily(current_start, current_end)},
        "previous": {**previous, "start": previous_start.strftime("%Y-%m-%d"), "end": previous_end.strftime("%Y-%m-%d"), "daily": _daily(previous_start, previous_end)},
        "changes": changes,
    }), 200


@comparisons_bp.route("/products", methods=["GET"])
@jwt_required()
def product_comparison():
    """Compare performance metrics for specific products.

    Query params:
      ids — comma-separated product IDs (e.g. ids=1,2,3), up to 10
    """
    ids_raw = request.args.get("ids", "")
    try:
        product_ids = [int(x) for x in ids_raw.split(",") if x.strip()][:10]
    except ValueError:
        return jsonify({"error": "ids must be comma-separated integers"}), 400

    if len(product_ids) < 2:
        return jsonify({"error": "Provide at least 2 product IDs to compare"}), 400

    products = Product.query.filter(Product.id.in_(product_ids)).all()
    if len(products) < 2:
        return jsonify({"error": "At least 2 valid products required"}), 404

    product_map = {p.id: p for p in products}

    # Aggregate sales per product
    rows = (
        db.session.query(
            SaleItem.product_id,
            func.sum(SaleItem.quantity).label("total_sold"),
            func.sum(SaleItem.subtotal).label("total_revenue"),
            func.count(func.distinct(SaleItem.sale_id)).label("order_count"),
        )
        .filter(SaleItem.product_id.in_(product_ids))
        .group_by(SaleItem.product_id)
        .all()
    )
    stats_map = {r.product_id: r for r in rows}

    result = []
    for pid in product_ids:
        p = product_map.get(pid)
        if not p:
            continue
        stats = stats_map.get(pid)
        result.append({
            "id": p.id,
            "name": p.name,
            "sku": p.sku,
            "price": p.price,
            "current_stock": p.quantity,
            "category": p.category,
            "total_sold": int(stats.total_sold) if stats else 0,
            "total_revenue": round(float(stats.total_revenue), 2) if stats else 0.0,
            "order_count": stats.order_count if stats else 0,
        })

    # Monthly trend per product (last 6 months)
    six_months_ago = datetime.now(timezone.utc) - timedelta(days=180)
    trend_rows = (
        db.session.query(
            SaleItem.product_id,
            func.strftime("%Y-%m", Sale.created_at).label("month"),
            func.sum(SaleItem.quantity).label("units"),
            func.sum(SaleItem.subtotal).label("revenue"),
        )
        .join(Sale, Sale.id == SaleItem.sale_id)
        .filter(SaleItem.product_id.in_(product_ids), Sale.created_at >= six_months_ago)
        .group_by(SaleItem.product_id, func.strftime("%Y-%m", Sale.created_at))
        .order_by(func.strftime("%Y-%m", Sale.created_at))
        .all()
    )

    trends = {}
    for row in trend_rows:
        trends.setdefault(row.product_id, []).append({
            "month": row.month,
            "units": int(row.units),
            "revenue": round(float(row.revenue), 2),
        })

    for item in result:
        item["monthly_trend"] = trends.get(item["id"], [])

    return jsonify({"products": result}), 200


@comparisons_bp.route("/categories", methods=["GET"])
@jwt_required()
def category_comparison():
    """Compare aggregate metrics across product categories."""
    rows = (
        db.session.query(
            Product.category,
            func.count(func.distinct(Product.id)).label("product_count"),
            func.coalesce(func.sum(SaleItem.quantity), 0).label("total_sold"),
            func.coalesce(func.sum(SaleItem.subtotal), 0).label("total_revenue"),
        )
        .outerjoin(SaleItem, SaleItem.product_id == Product.id)
        .group_by(Product.category)
        .order_by(func.sum(SaleItem.subtotal).desc())
        .all()
    )

    # Inventory value per category
    inv_rows = (
        db.session.query(
            Product.category,
            func.sum(Product.price * Product.quantity).label("inventory_value"),
            func.sum(Product.quantity).label("total_stock"),
        )
        .group_by(Product.category)
        .all()
    )
    inv_map = {r.category: r for r in inv_rows}

    result = []
    for row in rows:
        inv = inv_map.get(row.category)
        result.append({
            "category": row.category,
            "product_count": row.product_count,
            "total_sold": int(row.total_sold),
            "total_revenue": round(float(row.total_revenue), 2),
            "inventory_value": round(float(inv.inventory_value), 2) if inv else 0.0,
            "total_stock": int(inv.total_stock) if inv else 0,
        })

    return jsonify({"categories": result}), 200


@comparisons_bp.route("/agents", methods=["GET"])
@jwt_required()
def agent_comparison():
    """Compare sales performance across agents (admin sees all, agent sees self only)."""
    user = User.query.get(get_jwt_identity())

    query = (
        db.session.query(
            User.id.label("agent_id"),
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

    agents = []
    for row in rows:
        avg_order = round(float(row.total_revenue) / row.sale_count, 2) if row.sale_count else 0.0

        # Units sold by this agent
        units = (
            db.session.query(func.coalesce(func.sum(SaleItem.quantity), 0))
            .join(Sale, Sale.id == SaleItem.sale_id)
            .filter(Sale.agent_id == row.agent_id)
            .scalar()
        )

        agents.append({
            "agent_id": row.agent_id,
            "username": row.username,
            "sale_count": row.sale_count,
            "total_revenue": round(float(row.total_revenue), 2),
            "avg_order_value": avg_order,
            "units_sold": int(units),
        })

    return jsonify({"agents": agents}), 200
