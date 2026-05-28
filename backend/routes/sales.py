"""Sales routes: create sales, list sales, get sale details."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from marshmallow import ValidationError

from extensions import db
from models import Sale, SaleItem, Product
from schemas import create_sale_schema
from middleware.auth import admin_required

sales_bp = Blueprint("sales", __name__, url_prefix="/api/sales")


@sales_bp.route("", methods=["POST"])
@jwt_required()
def create_sale():
    """Create a new sale transaction. Decrements product inventory."""
    try:
        data = create_sale_schema.load(request.get_json())
    except ValidationError as err:
        return jsonify({"errors": err.messages}), 400

    agent_id = get_jwt_identity()
    sale = Sale(agent_id=agent_id, total_amount=0)

    total = 0.0
    for item_data in data["items"]:
        product = Product.query.get(item_data["product_id"])
        if not product:
            return jsonify({"error": f"Product {item_data['product_id']} not found"}), 404
        if product.quantity < item_data["quantity"]:
            return jsonify({
                "error": f"Insufficient stock for '{product.name}'. Available: {product.quantity}"
            }), 400

        subtotal = product.price * item_data["quantity"]
        sale_item = SaleItem(
            product_id=product.id,
            quantity=item_data["quantity"],
            unit_price=product.price,
            subtotal=subtotal,
        )
        sale.items.append(sale_item)

        # Decrement inventory
        product.quantity -= item_data["quantity"]
        total += subtotal

    sale.total_amount = round(total, 2)
    db.session.add(sale)
    db.session.commit()

    return jsonify({"sale": sale.to_dict()}), 201


@sales_bp.route("", methods=["GET"])
@jwt_required()
def list_sales():
    """List sales. Admins see all; agents see only their own."""
    from models import User
    user = User.query.get(get_jwt_identity())
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    query = Sale.query
    if user.role != "admin":
        query = query.filter_by(agent_id=user.id)

    paginated = query.order_by(Sale.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return jsonify({
        "sales": [s.to_dict() for s in paginated.items],
        "total": paginated.total,
        "page": paginated.page,
        "pages": paginated.pages,
    }), 200


@sales_bp.route("/<int:sale_id>", methods=["GET"])
@jwt_required()
def get_sale(sale_id):
    """Get sale details by ID."""
    from models import User
    user = User.query.get(get_jwt_identity())
    sale = Sale.query.get(sale_id)
    if not sale:
        return jsonify({"error": "Sale not found"}), 404

    # Non-admins can only view their own sales
    if user.role != "admin" and sale.agent_id != user.id:
        return jsonify({"error": "Access denied"}), 403

    return jsonify({"sale": sale.to_dict()}), 200
