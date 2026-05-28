import React from "react";

function StatsCard({ title, value, change, changeType }) {
  return (
    <div className="stats-card">
      <p className="stats-title">{title}</p>
      <h3 className="stats-value">{value}</h3>
      <p className={`stats-change ${changeType}`}>
        {changeType === "positive" ? "↑" : "↓"} {change}
      </p>
    </div>
  );
}

export default StatsCard;
