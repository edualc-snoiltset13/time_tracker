import React from "react";
import {
  LineChart, Line, AreaChart, Area, BarChart, Bar,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts";
import StatsCard from "../components/StatsCard";
import RecentOrders from "../components/RecentOrders";

const revenueData = [
  { month: "Jan", revenue: 4200 },
  { month: "Feb", revenue: 5800 },
  { month: "Mar", revenue: 4900 },
  { month: "Apr", revenue: 7200 },
  { month: "May", revenue: 6800 },
  { month: "Jun", revenue: 8100 },
  { month: "Jul", revenue: 7400 },
];

const visitorData = [
  { day: "Mon", visitors: 1200 },
  { day: "Tue", visitors: 1800 },
  { day: "Wed", visitors: 1400 },
  { day: "Thu", visitors: 2200 },
  { day: "Fri", visitors: 1900 },
  { day: "Sat", visitors: 2600 },
  { day: "Sun", visitors: 2100 },
];

const salesData = [
  { category: "Electronics", sales: 4300 },
  { category: "Clothing", sales: 2800 },
  { category: "Food", sales: 1900 },
  { category: "Books", sales: 1200 },
  { category: "Other", sales: 800 },
];

function Dashboard() {
  return (
    <div className="dashboard">
      <div className="stats-grid">
        <StatsCard title="Total Revenue" value="$48,200" change="12.5% vs last month" changeType="positive" />
        <StatsCard title="Active Users" value="2,847" change="8.2% vs last month" changeType="positive" />
        <StatsCard title="Orders" value="1,024" change="3.1% vs last month" changeType="negative" />
        <StatsCard title="Conversion" value="3.6%" change="1.2% vs last month" changeType="positive" />
      </div>

      <div className="charts-grid">
        <div className="card">
          <h3>Revenue Overview</h3>
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis dataKey="month" stroke="#888" />
              <YAxis stroke="#888" />
              <Tooltip contentStyle={{ backgroundColor: "#1e1e2f", border: "1px solid #333" }} />
              <Area type="monotone" dataKey="revenue" stroke="#6366f1" fill="#6366f140" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h3>Weekly Visitors</h3>
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={visitorData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis dataKey="day" stroke="#888" />
              <YAxis stroke="#888" />
              <Tooltip contentStyle={{ backgroundColor: "#1e1e2f", border: "1px solid #333" }} />
              <Line type="monotone" dataKey="visitors" stroke="#22d3ee" strokeWidth={2} dot={{ r: 4 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="charts-grid">
        <div className="card">
          <h3>Sales by Category</h3>
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={salesData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#333" />
              <XAxis dataKey="category" stroke="#888" />
              <YAxis stroke="#888" />
              <Tooltip contentStyle={{ backgroundColor: "#1e1e2f", border: "1px solid #333" }} />
              <Bar dataKey="sales" fill="#a78bfa" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <RecentOrders />
      </div>
    </div>
  );
}

export default Dashboard;
