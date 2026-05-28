import React from "react";
import { useLocation } from "react-router-dom";

const pageTitles = {
  "/": "Dashboard",
  "/users": "Users",
  "/analytics": "Analytics",
  "/settings": "Settings",
};

function Header() {
  const location = useLocation();
  const title = pageTitles[location.pathname] || "Dashboard";

  return (
    <header className="header">
      <h1>{title}</h1>
      <div className="header-right">
        <input
          type="search"
          placeholder="Search..."
          className="search-input"
        />
        <div className="avatar">A</div>
      </div>
    </header>
  );
}

export default Header;
