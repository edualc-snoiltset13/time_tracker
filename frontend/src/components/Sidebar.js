import React from "react";
import { NavLink } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function Sidebar() {
  const { user, logout } = useAuth();

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">Inventory & Sales</div>
      <nav className="sidebar-nav">
        <NavLink to="/" className={({ isActive }) => (isActive ? "active" : "")}>
          Dashboard
        </NavLink>
        <NavLink to="/products" className={({ isActive }) => (isActive ? "active" : "")}>
          Products
        </NavLink>
        <NavLink to="/sales" className={({ isActive }) => (isActive ? "active" : "")}>
          Sales
        </NavLink>
        <NavLink to="/sales/new" className={({ isActive }) => (isActive ? "active" : "")}>
          + New Sale
        </NavLink>
        <NavLink to="/comparisons" className={({ isActive }) => (isActive ? "active" : "")}>
          Comparisons
        </NavLink>
      </nav>
      <div className="sidebar-footer">
        <div>
          {user?.username}{" "}
          <span className={`badge ${user?.role === "admin" ? "badge-admin" : "badge-agent"}`}>
            {user?.role}
          </span>
        </div>
        <button onClick={logout} style={{ marginTop: "0.5rem" }}>
          Sign out
        </button>
      </div>
    </aside>
  );
}
