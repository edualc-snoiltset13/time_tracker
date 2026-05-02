import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import api from "../services/api";

export default function NewSale() {
  const navigate = useNavigate();
  const [products, setProducts] = useState([]);
  const [items, setItems] = useState([{ product_id: "", quantity: 1 }]);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    api.get("/products", { params: { per_page: 200 } })
      .then(({ data }) => setProducts(data.products))
      .catch(console.error);
  }, []);

  const addLine = () => setItems([...items, { product_id: "", quantity: 1 }]);

  const removeLine = (idx) => {
    if (items.length <= 1) return;
    setItems(items.filter((_, i) => i !== idx));
  };

  const updateLine = (idx, field, value) => {
    const updated = [...items];
    updated[idx] = { ...updated[idx], [field]: value };
    setItems(updated);
  };

  const getLineTotal = (item) => {
    const product = products.find((p) => p.id === Number(item.product_id));
    if (!product) return 0;
    return product.price * item.quantity;
  };

  const grandTotal = items.reduce((sum, item) => sum + getLineTotal(item), 0);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    const saleItems = items
      .filter((item) => item.product_id)
      .map((item) => ({ product_id: Number(item.product_id), quantity: Number(item.quantity) }));

    if (saleItems.length === 0) {
      setError("Add at least one product");
      return;
    }

    setSubmitting(true);
    try {
      await api.post("/sales", { items: saleItems });
      navigate("/sales");
    } catch (err) {
      setError(err.response?.data?.error || "Sale creation failed");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>New Sale</h1>
      </div>

      <div className="card">
        {error && <p className="error-text">{error}</p>}
        <form onSubmit={handleSubmit}>
          <table>
            <thead>
              <tr>
                <th>Product</th>
                <th style={{ width: "100px" }}>Qty</th>
                <th style={{ width: "120px" }}>Subtotal</th>
                <th style={{ width: "60px" }}></th>
              </tr>
            </thead>
            <tbody>
              {items.map((item, idx) => (
                <tr key={idx}>
                  <td>
                    <select
                      value={item.product_id}
                      onChange={(e) => updateLine(idx, "product_id", e.target.value)}
                      required
                      style={{ width: "100%", padding: "0.5rem" }}
                    >
                      <option value="">Select product...</option>
                      {products.map((p) => (
                        <option key={p.id} value={p.id} disabled={p.quantity === 0}>
                          {p.name} (${p.price.toFixed(2)}) — Stock: {p.quantity}
                        </option>
                      ))}
                    </select>
                  </td>
                  <td>
                    <input
                      type="number"
                      min="1"
                      value={item.quantity}
                      onChange={(e) => updateLine(idx, "quantity", parseInt(e.target.value, 10) || 1)}
                      style={{ width: "100%", padding: "0.5rem" }}
                    />
                  </td>
                  <td style={{ fontWeight: 600 }}>
                    ${getLineTotal(item).toFixed(2)}
                  </td>
                  <td>
                    <button type="button" className="btn btn-danger btn-sm" onClick={() => removeLine(idx)}>
                      X
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div style={{ marginTop: "1rem", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <button type="button" className="btn btn-secondary" onClick={addLine}>
              + Add Line Item
            </button>
            <div style={{ fontSize: "1.2rem", fontWeight: 700 }}>
              Total: ${grandTotal.toFixed(2)}
            </div>
          </div>

          <div className="modal-actions">
            <button type="button" className="btn btn-secondary" onClick={() => navigate("/sales")}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary" disabled={submitting}>
              {submitting ? "Processing..." : "Complete Sale"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
