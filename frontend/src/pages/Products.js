import React, { useEffect, useState, useCallback } from "react";
import api from "../services/api";
import { useAuth } from "../context/AuthContext";

export default function Products() {
  const { isAdmin } = useAuth();
  const [products, setProducts] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("");
  const [categories, setCategories] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ name: "", sku: "", description: "", price: "", quantity: "", category: "General" });
  const [error, setError] = useState("");

  const loadProducts = useCallback(async () => {
    try {
      const { data } = await api.get("/products", { params: { search, category, page, per_page: 15 } });
      setProducts(data.products);
      setTotal(data.total);
      setPages(data.pages);
    } catch (err) {
      console.error(err);
    }
  }, [search, category, page]);

  const loadCategories = useCallback(async () => {
    try {
      const { data } = await api.get("/products/categories");
      setCategories(data.categories);
    } catch (err) {
      console.error(err);
    }
  }, []);

  useEffect(() => { loadProducts(); }, [loadProducts]);
  useEffect(() => { loadCategories(); }, [loadCategories]);

  const openCreate = () => {
    setEditing(null);
    setForm({ name: "", sku: "", description: "", price: "", quantity: "", category: "General" });
    setError("");
    setShowModal(true);
  };

  const openEdit = (product) => {
    setEditing(product);
    setForm({
      name: product.name,
      sku: product.sku,
      description: product.description || "",
      price: String(product.price),
      quantity: String(product.quantity),
      category: product.category,
    });
    setError("");
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    const payload = { ...form, price: parseFloat(form.price), quantity: parseInt(form.quantity, 10) };
    try {
      if (editing) {
        await api.put(`/products/${editing.id}`, payload);
      } else {
        await api.post("/products", payload);
      }
      setShowModal(false);
      loadProducts();
      loadCategories();
    } catch (err) {
      setError(err.response?.data?.error || err.response?.data?.errors ? JSON.stringify(err.response.data.errors || err.response.data.error) : "Failed");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this product?")) return;
    try {
      await api.delete(`/products/${id}`);
      loadProducts();
      loadCategories();
    } catch (err) {
      alert(err.response?.data?.error || "Delete failed");
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>Products ({total})</h1>
        {isAdmin && <button className="btn btn-primary" onClick={openCreate}>+ Add Product</button>}
      </div>

      <div className="search-bar">
        <input
          placeholder="Search by name or SKU..."
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
        />
        <select value={category} onChange={(e) => { setCategory(e.target.value); setPage(1); }}>
          <option value="">All Categories</option>
          {categories.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
      </div>

      <div className="card">
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>SKU</th>
                <th>Category</th>
                <th>Price</th>
                <th>Stock</th>
                {isAdmin && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td>{p.name}</td>
                  <td>{p.sku}</td>
                  <td>{p.category}</td>
                  <td>${p.price.toFixed(2)}</td>
                  <td style={{ color: p.quantity < 10 ? "#e74c3c" : "inherit", fontWeight: p.quantity < 10 ? 600 : 400 }}>
                    {p.quantity}
                  </td>
                  {isAdmin && (
                    <td>
                      <button className="btn btn-secondary btn-sm" onClick={() => openEdit(p)} style={{ marginRight: "0.5rem" }}>
                        Edit
                      </button>
                      <button className="btn btn-danger btn-sm" onClick={() => handleDelete(p.id)}>
                        Delete
                      </button>
                    </td>
                  )}
                </tr>
              ))}
              {products.length === 0 && (
                <tr><td colSpan={isAdmin ? 6 : 5} style={{ textAlign: "center", padding: "2rem" }}>No products found</td></tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {pages > 1 && (
          <div style={{ display: "flex", justifyContent: "center", gap: "0.5rem", marginTop: "1rem" }}>
            <button className="btn btn-secondary btn-sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>Prev</button>
            <span style={{ lineHeight: "2rem" }}>Page {page} of {pages}</span>
            <button className="btn btn-secondary btn-sm" disabled={page >= pages} onClick={() => setPage(page + 1)}>Next</button>
          </div>
        )}
      </div>

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h3>{editing ? "Edit Product" : "New Product"}</h3>
            {error && <p className="error-text">{error}</p>}
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Name</label>
                <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>SKU</label>
                <input value={form.sku} onChange={(e) => setForm({ ...form, sku: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Description</label>
                <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={2} />
              </div>
              <div className="form-group">
                <label>Price ($)</label>
                <input type="number" step="0.01" min="0" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Quantity</label>
                <input type="number" min="0" value={form.quantity} onChange={(e) => setForm({ ...form, quantity: e.target.value })} required />
              </div>
              <div className="form-group">
                <label>Category</label>
                <input value={form.category} onChange={(e) => setForm({ ...form, category: e.target.value })} />
              </div>
              <div className="modal-actions">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>Cancel</button>
                <button type="submit" className="btn btn-primary">{editing ? "Update" : "Create"}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
