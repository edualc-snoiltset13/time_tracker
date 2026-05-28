import React, { useEffect, useState, useCallback } from "react";
import { Link } from "react-router-dom";
import api from "../services/api";

export default function Sales() {
  const [sales, setSales] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [expandedId, setExpandedId] = useState(null);

  const loadSales = useCallback(async () => {
    try {
      const { data } = await api.get("/sales", { params: { page, per_page: 15 } });
      setSales(data.sales);
      setTotal(data.total);
      setPages(data.pages);
    } catch (err) {
      console.error(err);
    }
  }, [page]);

  useEffect(() => { loadSales(); }, [loadSales]);

  return (
    <div>
      <div className="page-header">
        <h1>Sales ({total})</h1>
        <Link to="/sales/new" className="btn btn-primary">+ New Sale</Link>
      </div>

      <div className="card">
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Date</th>
                <th>Agent</th>
                <th>Items</th>
                <th>Total</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {sales.map((sale) => (
                <React.Fragment key={sale.id}>
                  <tr
                    onClick={() => setExpandedId(expandedId === sale.id ? null : sale.id)}
                    style={{ cursor: "pointer" }}
                  >
                    <td>#{sale.id}</td>
                    <td>{new Date(sale.created_at).toLocaleDateString()}</td>
                    <td>{sale.agent_name}</td>
                    <td>{sale.items.length} item(s)</td>
                    <td style={{ fontWeight: 600 }}>${sale.total_amount.toFixed(2)}</td>
                    <td>
                      <span className={`badge ${sale.status === "completed" ? "badge-agent" : "badge-admin"}`}>
                        {sale.status}
                      </span>
                    </td>
                  </tr>
                  {expandedId === sale.id && (
                    <tr>
                      <td colSpan={6} style={{ background: "#f8f9fa", padding: "1rem" }}>
                        <strong>Line Items:</strong>
                        <table style={{ marginTop: "0.5rem" }}>
                          <thead>
                            <tr><th>Product</th><th>Qty</th><th>Unit Price</th><th>Subtotal</th></tr>
                          </thead>
                          <tbody>
                            {sale.items.map((item) => (
                              <tr key={item.id}>
                                <td>{item.product_name}</td>
                                <td>{item.quantity}</td>
                                <td>${item.unit_price.toFixed(2)}</td>
                                <td>${item.subtotal.toFixed(2)}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))}
              {sales.length === 0 && (
                <tr><td colSpan={6} style={{ textAlign: "center", padding: "2rem" }}>No sales found</td></tr>
              )}
            </tbody>
          </table>
        </div>

        {pages > 1 && (
          <div style={{ display: "flex", justifyContent: "center", gap: "0.5rem", marginTop: "1rem" }}>
            <button className="btn btn-secondary btn-sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>Prev</button>
            <span style={{ lineHeight: "2rem" }}>Page {page} of {pages}</span>
            <button className="btn btn-secondary btn-sm" disabled={page >= pages} onClick={() => setPage(page + 1)}>Next</button>
          </div>
        )}
      </div>
    </div>
  );
}
