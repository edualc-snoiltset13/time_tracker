import React from "react";
import {
  PieChart, Pie, Cell,
  BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from "recharts";

const trafficSources = [
  { name: "Direct", value: 4200 },
  { name: "Organic", value: 3100 },
  { name: "Referral", value: 1800 },
  { name: "Social", value: 1400 },
  { name: "Email", value: 900 },
];

const COLORS = ["#6366f1", "#22d3ee", "#a78bfa", "#f472b6", "#facc15"];

const monthlyMetrics = [
  { month: "Jan", pageViews: 12000, sessions: 4800 },
  { month: "Feb", pageViews: 15000, sessions: 5600 },
  { month: "Mar", pageViews: 13500, sessions: 5100 },
  { month: "Apr", pageViews: 18200, sessions: 7200 },
  { month: "May", pageViews: 16800, sessions: 6500 },
  { month: "Jun", pageViews: 21000, sessions: 8400 },
];

const topPages = [
  { page: "/home", views: 8400 },
  { page: "/products", views: 6200 },
  { page: "/pricing", views: 4800 },
  { page: "/about", views: 3100 },
  { page: "/blog", views: 2700 },
];

function Analytics() {
  return (
    <div className="analytics-page">
      <div className="stats-grid">
        <div className="stats-card">
          <p className="stats-title">Page Views</p>
          <h3 className="stats-value">96,500</h3>
        </div>
        <div className="stats-card">
          <p className="stats-title">Sessions</p>
          <h3 className="stats-value">37,600</h3>
        </div>
        <div className="stats-card">
          <p className="stats-title">Bounce Rate</p>
          <h3 className="stats-value">34.2%</h3>
        </div>
        <div className="stats-card">
          <p className="stats-title">Avg. Duration</p>
          <h3 className="stats-value">4m 12s</h3>
        </div>
      </div>

      <div className="charts-grid">
        <div className="card">
          <h3>Traffic Sources</h3>
          <ResponsiveContainer width="100%" height={280}>
            <PieChart>
              <Pie
                data={trafficSources}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) =>
                  `${name} ${(percent * 100).toFixed(0)}%`
                }
              >
                {trafficSources.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip contentStyle={{ backgroundColor: "#1e1e2f", border: "1px solid #333" }} />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h3>Monthly Metrics</h3>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={monthlyMetrics}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis dataKey="month" stroke="#888" />
              <YAxis stroke="#888" />
              <Tooltip contentStyle={{ backgroundColor: "#1e1e2f", border: "1px solid #333" }} />
              <Legend />
              <Bar dataKey="pageViews" fill="#6366f1" radius={[4, 4, 0, 0]} />
              <Bar dataKey="sessions" fill="#22d3ee" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="card">
        <h3>Top Pages</h3>
        <table>
          <thead>
            <tr>
              <th>Page</th>
              <th>Views</th>
              <th>Share</th>
            </tr>
          </thead>
          <tbody>
            {topPages.map((p) => (
              <tr key={p.page}>
                <td>{p.page}</td>
                <td>{p.views.toLocaleString()}</td>
                <td>
                  <div className="progress-bar">
                    <div
                      className="progress-fill"
                      style={{ width: `${(p.views / topPages[0].views) * 100}%` }}
                    />
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default Analytics;
