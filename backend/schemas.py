"""Marshmallow schemas for request validation and serialization."""

from extensions import ma
from marshmallow import fields, validate


# --- Auth Schemas ---

class RegisterSchema(ma.Schema):
    username = fields.String(required=True, validate=validate.Length(min=3, max=80))
    email = fields.Email(required=True)
    password = fields.String(required=True, validate=validate.Length(min=6))
    role = fields.String(validate=validate.OneOf(["admin", "sales_agent"]), load_default="sales_agent")


class LoginSchema(ma.Schema):
    username = fields.String(required=True)
    password = fields.String(required=True)


# --- Product Schemas ---

class ProductSchema(ma.Schema):
    name = fields.String(required=True, validate=validate.Length(min=1, max=120))
    sku = fields.String(required=True, validate=validate.Length(min=1, max=50))
    description = fields.String(load_default="")
    price = fields.Float(required=True, validate=validate.Range(min=0))
    quantity = fields.Integer(required=True, validate=validate.Range(min=0))
    category = fields.String(load_default="General", validate=validate.Length(max=80))


class ProductUpdateSchema(ma.Schema):
    name = fields.String(validate=validate.Length(min=1, max=120))
    sku = fields.String(validate=validate.Length(min=1, max=50))
    description = fields.String()
    price = fields.Float(validate=validate.Range(min=0))
    quantity = fields.Integer(validate=validate.Range(min=0))
    category = fields.String(validate=validate.Length(max=80))


# --- Sale Schemas ---

class SaleItemSchema(ma.Schema):
    product_id = fields.Integer(required=True)
    quantity = fields.Integer(required=True, validate=validate.Range(min=1))


class CreateSaleSchema(ma.Schema):
    items = fields.List(fields.Nested(SaleItemSchema), required=True, validate=validate.Length(min=1))


# Schema instances
register_schema = RegisterSchema()
login_schema = LoginSchema()
product_schema = ProductSchema()
product_update_schema = ProductUpdateSchema()
create_sale_schema = CreateSaleSchema()
