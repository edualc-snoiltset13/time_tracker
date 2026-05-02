import React, { useEffect, useState } from "react";
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, Legend, PieChart, Pie, Cell,
} from "recharts";
import api from "../services/api";

const COLORS = ["#4361ee", "#2ecc71", "#e74c3c", "#f39c12", "#9b59b6", "#1abc9c", "#e67e22", "#3498db"];

export default function Dashboard() {
  const [summary, setSummary] = useState(null);
  const [salesOverTime, setSalesOverTime] = useState([]);
  const [topProducts, setTopProducts] = useState([]);
  const [agentData, setAgentData] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [sumRes, sotRes, topRes, agentRes] = await Promise.all([
          api.get("/dashboard/summary"),
          api.get("/dashboard/sales-over-time?days=30"),
          api.get("/dashboard/top-products?limit=8"),
          api.get("/dashboard/sales-by-agent"),
        ]);
        setSummary(sumRes.data);
        setSalesOverTime(sotRes.data.data);
        setTopProducts(topRes.data.data);
        setAgentData(agentRes.data.data);
      } catch (err) {
        console.error("Dashboard load error:", err);
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  if (loading) return <p>Loading dashboard...</p>;

  return (
    <div>
      <div className="page-header">
        <h1>Dashboard</h1>
      </div>

      {/* KPI Cards */}
      {summary && (
        <div className="kpi-row">
          <div className="kpi-card revenue">
            <div className="label">Total Revenue</div>
            <div className="value">${summary.total_revenue.toLocaleString()}</div>
          </div>
          <div className="kpi-card sales">
            <div className="label">Total Sales</div>
            <div className="value">{summary.sales_count}</div>
          </div>
          <div className="kpi-card products">
            <div className="label">Products</div>
            <div className="value">{summary.product_count}</div>
          </div>
          <div className="kpi-card low-stock">
            <div className="label">Low Stock Items</div>
            <div className="value">{summary.low_stock_count}</div>
          </div>
        </div>
      )}

      {/* Charts */}
      <div className="charts-row">
        {/* Sales Over Time */}
        <div className="card">
          <div className="card-title">Revenue Over Time (30 days)</div>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={salesOverTime}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip formatter={(v) => `$${v.toFixed(2)}`} />
              <Legend />
              <Line type="monotone" dataKey="revenue" stroke="#4361ee" strokeWidth={2} name="Revenue" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Top Products Bar Chart */}
        <div className="card">
          <div className="card-title">Top Products by Units Sold</div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={topProducts}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Bar dataKey="total_sold" fill="#9b59b6" name="Units Sold" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Sales by Agent Pie Chart */}
        <div className="card">
          <div className="card-title">Revenue by Agent</div>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={agentData}
                dataKey="total_revenue"
                nameKey="agent"
                cx="50%"
                cy="50%"
                outerRadius={100}
                label={({ agent, total_revenue }) => `${agent}: $${total_revenue}`}
              >
                {agentData.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip formatter={(v) => `$${v.toFixed(2)}`} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
