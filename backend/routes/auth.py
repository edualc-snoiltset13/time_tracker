"""Authentication routes: register, login, profile."""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from marshmallow import ValidationError

from extensions import db
from models import User
from schemas import register_schema, login_schema

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.route("/register", methods=["POST"])
def register():
    """Register a new user account."""
    try:
        data = register_schema.load(request.get_json())
    except ValidationError as err:
        return jsonify({"errors": err.messages}), 400

    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "Username already exists"}), 409
    if User.query.filter_by(email=data["email"]).first():
        return jsonify({"error": "Email already exists"}), 409

    user = User(
        username=data["username"],
        email=data["email"],
        role=data.get("role", "sales_agent"),
    )
    user.set_password(data["password"])

    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=user.id)
    return jsonify({"token": token, "user": user.to_dict()}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    """Authenticate user and return JWT token."""
    try:
        data = login_schema.load(request.get_json())
    except ValidationError as err:
        return jsonify({"errors": err.messages}), 400

    user = User.query.filter_by(username=data["username"]).first()
    if not user or not user.check_password(data["password"]):
        return jsonify({"error": "Invalid username or password"}), 401

    token = create_access_token(identity=user.id)
    return jsonify({"token": token, "user": user.to_dict()}), 200


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def get_profile():
    """Return the current authenticated user's profile."""
    user = User.query.get(get_jwt_identity())
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify({"user": user.to_dict()}), 200
