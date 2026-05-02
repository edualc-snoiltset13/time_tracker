import React, { useEffect, useState, useCallback } from "react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, Legend, RadarChart, PolarGrid,
  PolarAngleAxis, PolarRadiusAxis, Radar,
} from "recharts";
import api from "../services/api";
import { useAuth } from "../context/AuthContext";

const COLORS = ["#4361ee", "#2ecc71", "#e74c3c", "#f39c12", "#9b59b6", "#1abc9c"];

function ChangeIndicator({ value }) {
  if (value === null || value === undefined) return <span style={{ color: "#999" }}>N/A</span>;
  const color = value > 0 ? "#2ecc71" : value < 0 ? "#e74c3c" : "#999";
  const arrow = value > 0 ? "▲" : value < 0 ? "▼" : "";
  return <span style={{ color, fontWeight: 600 }}>{arrow} {Math.abs(value)}%</span>;
}

/* ---- Period Comparison Tab ---- */
function PeriodComparison() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/comparisons/period")
      .then(({ data }) => setData(data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p>Loading period data...</p>;
  if (!data) return <p>No data available</p>;

  const metrics = [
    { label: "Revenue", key: "revenue", fmt: (v) => `$${v.toLocaleString()}` },
    { label: "Sales Count", key: "sale_count", fmt: (v) => v },
    { label: "Units Sold", key: "units_sold", fmt: (v) => v },
    { label: "Avg Order Value", key: "avg_order_value", fmt: (v) => `$${v.toFixed(2)}` },
  ];

  const barData = metrics.map((m) => ({
    metric: m.label,
    Current: data.current[m.key],
    Previous: data.previous[m.key],
  }));

  return (
    <div>
      <p style={{ color: "#666", marginBottom: "1rem" }}>
        Current: {data.current.start} to {data.current.end} vs. Previous: {data.previous.start} to {data.previous.end}
      </p>

      {/* KPI comparison cards */}
      <div className="kpi-row" style={{ marginBottom: "1.5rem" }}>
        {metrics.map((m) => (
          <div className="kpi-card" key={m.key}>
            <div className="label">{m.label}</div>
            <div className="value" style={{ fontSize: "1.4rem" }}>{m.fmt(data.current[m.key])}</div>
            <div style={{ fontSize: "0.8rem", marginTop: "0.25rem" }}>
              was {m.fmt(data.previous[m.key])} {" "}
              <ChangeIndicator value={data.changes[m.key]} />
            </div>
          </div>
        ))}
      </div>

      {/* Side by side bar chart */}
      <div className="card">
        <div className="card-title">Period Metrics Comparison</div>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={barData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="metric" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Legend />
            <Bar dataKey="Current" fill="#4361ee" />
            <Bar dataKey="Previous" fill="#bbb" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

/* ---- Product Comparison Tab ---- */
function ProductComparison() {
  const [products, setProducts] = useState([]);
  const [selectedIds, setSelectedIds] = useState([]);
  const [compData, setCompData] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    api.get("/products", { params: { per_page: 200 } })
      .then(({ data }) => setProducts(data.products))
      .catch(console.error);
  }, []);

  const toggleProduct = (id) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : prev.length < 10 ? [...prev, id] : prev
    );
  };

  const compare = useCallback(async () => {
    if (selectedIds.length < 2) return;
    setLoading(true);
    try {
      const { data } = await api.get(`/comparisons/products?ids=${selectedIds.join(",")}`);
      setCompData(data.products);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [selectedIds]);

  // Normalize values for radar chart (0–100 scale per metric)
  const radarData = compData
    ? (() => {
        const metrics = ["total_sold", "total_revenue", "current_stock", "order_count"];
        const labels = ["Units Sold", "Revenue", "Stock", "Orders"];
        return metrics.map((key, i) => {
          const maxVal = Math.max(...compData.map((p) => p[key]), 1);
          const entry = { metric: labels[i] };
          compData.forEach((p) => { entry[p.name] = Math.round((p[key] / maxVal) * 100); });
          return entry;
        });
      })()
    : [];

  return (
    <div>
      {/* Product selector */}
      <div className="card" style={{ marginBottom: "1rem" }}>
        <div className="card-title">Select Products to Compare (2–10)</div>
        <div style={{ display: "flex", flexWrap: "wrap", gap: "0.5rem", marginBottom: "1rem" }}>
          {products.map((p) => (
            <button
              key={p.id}
              className={`btn btn-sm ${selectedIds.includes(p.id) ? "btn-primary" : "btn-secondary"}`}
              onClick={() => toggleProduct(p.id)}
            >
              {p.name}
            </button>
          ))}
        </div>
        <button className="btn btn-primary" onClick={compare} disabled={selectedIds.length < 2 || loading}>
          {loading ? "Comparing..." : `Compare (${selectedIds.length} selected)`}
        </button>
      </div>

      {compData && (
        <>
          {/* Data table */}
          <div className="card">
            <div className="card-title">Product Metrics</div>
            <div className="table-container">
              <table>
                <thead>
                  <tr>
                    <th>Metric</th>
                    {compData.map((p) => <th key={p.id}>{p.name}</th>)}
                  </tr>
                </thead>
                <tbody>
                  <tr><td>SKU</td>{compData.map((p) => <td key={p.id}>{p.sku}</td>)}</tr>
                  <tr><td>Price</td>{compData.map((p) => <td key={p.id}>${p.price.toFixed(2)}</td>)}</tr>
                  <tr><td>Current Stock</td>{compData.map((p) => <td key={p.id} style={{ color: p.current_stock < 10 ? "#e74c3c" : "inherit" }}>{p.current_stock}</td>)}</tr>
                  <tr><td>Units Sold</td>{compData.map((p) => <td key={p.id} style={{ fontWeight: 600 }}>{p.total_sold}</td>)}</tr>
                  <tr><td>Revenue</td>{compData.map((p) => <td key={p.id} style={{ fontWeight: 600 }}>${p.total_revenue.toFixed(2)}</td>)}</tr>
                  <tr><td>Orders</td>{compData.map((p) => <td key={p.id}>{p.order_count}</td>)}</tr>
                  <tr><td>Category</td>{compData.map((p) => <td key={p.id}>{p.category}</td>)}</tr>
                </tbody>
              </table>
            </div>
          </div>

          {/* Radar chart */}
          <div className="charts-row" style={{ marginTop: "1.5rem" }}>
            <div className="card">
              <div className="card-title">Performance Radar (normalized)</div>
              <ResponsiveContainer width="100%" height={350}>
                <RadarChart data={radarData}>
                  <PolarGrid />
                  <PolarAngleAxis dataKey="metric" tick={{ fontSize: 12 }} />
                  <PolarRadiusAxis angle={30} domain={[0, 100]} tick={{ fontSize: 10 }} />
                  {compData.map((p, i) => (
                    <Radar key={p.id} name={p.name} dataKey={p.name}
                      stroke={COLORS[i % COLORS.length]} fill={COLORS[i % COLORS.length]} fillOpacity={0.15} />
                  ))}
                  <Legend />
                  <Tooltip />
                </RadarChart>
              </ResponsiveContainer>
            </div>

            {/* Revenue bar chart */}
            <div className="card">
              <div className="card-title">Revenue Comparison</div>
              <ResponsiveContainer width="100%" height={350}>
                <BarChart data={compData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip formatter={(v) => `$${v.toFixed(2)}`} />
                  <Bar dataKey="total_revenue" name="Revenue" fill="#4361ee" />
                  <Bar dataKey="total_sold" name="Units Sold" fill="#2ecc71" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

/* ---- Category Comparison Tab ---- */
function CategoryComparison() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/comparisons/categories")
      .then(({ data }) => setData(data.categories))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p>Loading categories...</p>;
  if (!data.length) return <p>No category data</p>;

  return (
    <div>
      <div className="card">
        <div className="card-title">Category Performance</div>
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Category</th>
                <th>Products</th>
                <th>Total Stock</th>
                <th>Inventory Value</th>
                <th>Units Sold</th>
                <th>Revenue</th>
              </tr>
            </thead>
            <tbody>
              {data.map((c) => (
                <tr key={c.category}>
                  <td style={{ fontWeight: 600 }}>{c.category}</td>
                  <td>{c.product_count}</td>
                  <td>{c.total_stock}</td>
                  <td>${c.inventory_value.toLocaleString()}</td>
                  <td>{c.total_sold}</td>
                  <td style={{ fontWeight: 600, color: "#2ecc71" }}>${c.total_revenue.toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="charts-row" style={{ marginTop: "1.5rem" }}>
        <div className="card">
          <div className="card-title">Revenue by Category</div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="category" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip formatter={(v) => `$${v.toFixed(2)}`} />
              <Legend />
              <Bar dataKey="total_revenue" name="Revenue" fill="#4361ee" />
              <Bar dataKey="inventory_value" name="Inventory Value" fill="#f39c12" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <div className="card-title">Units Sold vs Stock by Category</div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="category" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Legend />
              <Bar dataKey="total_sold" name="Units Sold" fill="#e74c3c" />
              <Bar dataKey="total_stock" name="Current Stock" fill="#2ecc71" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

/* ---- Agent Comparison Tab ---- */
function AgentComparison() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/comparisons/agents")
      .then(({ data }) => setData(data.agents))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p>Loading agent data...</p>;
  if (!data.length) return <p>No agent data</p>;

  // Radar data normalized per metric
  const radarMetrics = ["sale_count", "total_revenue", "units_sold", "avg_order_value"];
  const radarLabels = ["Sales", "Revenue", "Units", "Avg Order"];
  const radarData = radarMetrics.map((key, i) => {
    const maxVal = Math.max(...data.map((a) => a[key]), 1);
    const entry = { metric: radarLabels[i] };
    data.forEach((a) => { entry[a.username] = Math.round((a[key] / maxVal) * 100); });
    return entry;
  });

  return (
    <div>
      <div className="card">
        <div className="card-title">Agent Performance</div>
        <div className="table-container">
          <table>
            <thead>
              <tr>
                <th>Agent</th>
                <th>Sales</th>
                <th>Revenue</th>
                <th>Units Sold</th>
                <th>Avg Order</th>
              </tr>
            </thead>
            <tbody>
              {data.map((a) => (
                <tr key={a.agent_id}>
                  <td style={{ fontWeight: 600 }}>{a.username}</td>
                  <td>{a.sale_count}</td>
                  <td style={{ fontWeight: 600, color: "#2ecc71" }}>${a.total_revenue.toLocaleString()}</td>
                  <td>{a.units_sold}</td>
                  <td>${a.avg_order_value.toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="charts-row" style={{ marginTop: "1.5rem" }}>
        <div className="card">
          <div className="card-title">Agent Radar Comparison</div>
          <ResponsiveContainer width="100%" height={350}>
            <RadarChart data={radarData}>
              <PolarGrid />
              <PolarAngleAxis dataKey="metric" tick={{ fontSize: 12 }} />
              <PolarRadiusAxis angle={30} domain={[0, 100]} tick={{ fontSize: 10 }} />
              {data.map((a, i) => (
                <Radar key={a.agent_id} name={a.username} dataKey={a.username}
                  stroke={COLORS[i % COLORS.length]} fill={COLORS[i % COLORS.length]} fillOpacity={0.2} />
              ))}
              <Legend />
              <Tooltip />
            </RadarChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <div className="card-title">Revenue & Units by Agent</div>
          <ResponsiveContainer width="100%" height={350}>
            <BarChart data={data}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="username" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Legend />
              <Bar dataKey="total_revenue" name="Revenue ($)" fill="#4361ee" />
              <Bar dataKey="units_sold" name="Units Sold" fill="#9b59b6" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

/* ---- Main Page with Tabs ---- */
const TABS = [
  { key: "period", label: "Period vs Period" },
  { key: "products", label: "Product vs Product" },
  { key: "categories", label: "By Category" },
  { key: "agents", label: "By Agent" },
];

export default function Comparisons() {
  const { isAdmin } = useAuth();
  const [tab, setTab] = useState("period");

  return (
    <div>
      <div className="page-header">
        <h1>Data Comparisons</h1>
      </div>

      {/* Tab bar */}
      <div className="comparison-tabs">
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`comparison-tab ${tab === t.key ? "active" : ""}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div style={{ marginTop: "1.5rem" }}>
        {tab === "period" && <PeriodComparison />}
        {tab === "products" && <ProductComparison />}
        {tab === "categories" && <CategoryComparison />}
        {tab === "agents" && <AgentComparison />}
      </div>
    </div>
  );
}
