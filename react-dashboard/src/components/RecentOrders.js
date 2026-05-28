import React from "react";

const orders = [
  { id: "#1201", customer: "Alice Johnson", amount: "$240.00", status: "Completed", date: "2026-05-08" },
  { id: "#1202", customer: "Bob Smith", amount: "$125.50", status: "Pending", date: "2026-05-08" },
  { id: "#1203", customer: "Carol Davis", amount: "$890.00", status: "Completed", date: "2026-05-07" },
  { id: "#1204", customer: "Dan Wilson", amount: "$55.25", status: "Cancelled", date: "2026-05-07" },
  { id: "#1205", customer: "Eva Martinez", amount: "$340.00", status: "Pending", date: "2026-05-06" },
];

const statusClass = {
  Completed: "status-completed",
  Pending: "status-pending",
  Cancelled: "status-cancelled",
};

function RecentOrders() {
  return (
    <div className="card recent-orders">
      <h3>Recent Orders</h3>
      <table>
        <thead>
          <tr>
            <th>Order</th>
            <th>Customer</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr key={order.id}>
              <td>{order.id}</td>
              <td>{order.customer}</td>
              <td>{order.amount}</td>
              <td>
                <span className={`status-badge ${statusClass[order.status]}`}>
                  {order.status}
                </span>
              </td>
              <td>{order.date}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default RecentOrders;
