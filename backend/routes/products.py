"""Product CRUD routes."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from marshmallow import ValidationError

from extensions import db
from models import Product
from schemas import product_schema, product_update_schema
from middleware.auth import admin_required

products_bp = Blueprint("products", __name__, url_prefix="/api/products")


@products_bp.route("", methods=["GET"])
@jwt_required()
def list_products():
    """List all products with optional search and category filter."""
    search = request.args.get("search", "")
    category = request.args.get("category", "")
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    query = Product.query

    if search:
        query = query.filter(
            db.or_(
                Product.name.ilike(f"%{search}%"),
                Product.sku.ilike(f"%{search}%"),
            )
        )
    if category:
        query = query.filter(Product.category == category)

    paginated = query.order_by(Product.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return jsonify({
        "products": [p.to_dict() for p in paginated.items],
        "total": paginated.total,
        "page": paginated.page,
        "pages": paginated.pages,
    }), 200


@products_bp.route("/<int:product_id>", methods=["GET"])
@jwt_required()
def get_product(product_id):
    """Get a single product by ID."""
    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404
    return jsonify({"product": product.to_dict()}), 200


@products_bp.route("", methods=["POST"])
@admin_required
def create_product():
    """Create a new product (admin only)."""
    try:
        data = product_schema.load(request.get_json())
    except ValidationError as err:
        return jsonify({"errors": err.messages}), 400

    if Product.query.filter_by(sku=data["sku"]).first():
        return jsonify({"error": "SKU already exists"}), 409

    product = Product(**data)
    db.session.add(product)
    db.session.commit()

    return jsonify({"product": product.to_dict()}), 201


@products_bp.route("/<int:product_id>", methods=["PUT"])
@admin_required
def update_product(product_id):
    """Update an existing product (admin only)."""
    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    try:
        data = product_update_schema.load(request.get_json())
    except ValidationError as err:
        return jsonify({"errors": err.messages}), 400

    # Check SKU uniqueness if being changed
    if "sku" in data and data["sku"] != product.sku:
        if Product.query.filter_by(sku=data["sku"]).first():
            return jsonify({"error": "SKU already exists"}), 409

    for key, value in data.items():
        setattr(product, key, value)

    db.session.commit()
    return jsonify({"product": product.to_dict()}), 200


@products_bp.route("/<int:product_id>", methods=["DELETE"])
@admin_required
def delete_product(product_id):
    """Delete a product (admin only)."""
    product = Product.query.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404

    db.session.delete(product)
    db.session.commit()
    return jsonify({"message": "Product deleted"}), 200


@products_bp.route("/categories", methods=["GET"])
@jwt_required()
def list_categories():
    """Return distinct product categories."""
    rows = db.session.query(Product.category).distinct().all()
    categories = sorted(r[0] for r in rows if r[0])
    return jsonify({"categories": categories}), 200
