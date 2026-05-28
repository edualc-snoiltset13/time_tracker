import React, { useState } from "react";

const initialUsers = [
  { id: 1, name: "Alice Johnson", email: "alice@example.com", role: "Admin", status: "Active" },
  { id: 2, name: "Bob Smith", email: "bob@example.com", role: "Editor", status: "Active" },
  { id: 3, name: "Carol Davis", email: "carol@example.com", role: "Viewer", status: "Inactive" },
  { id: 4, name: "Dan Wilson", email: "dan@example.com", role: "Editor", status: "Active" },
  { id: 5, name: "Eva Martinez", email: "eva@example.com", role: "Admin", status: "Active" },
  { id: 6, name: "Frank Lee", email: "frank@example.com", role: "Viewer", status: "Inactive" },
  { id: 7, name: "Grace Chen", email: "grace@example.com", role: "Editor", status: "Active" },
  { id: 8, name: "Hank Brown", email: "hank@example.com", role: "Viewer", status: "Active" },
];

const statusClass = {
  Active: "status-completed",
  Inactive: "status-cancelled",
};

function Users() {
  const [search, setSearch] = useState("");

  const filtered = initialUsers.filter(
    (u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="users-page">
      <div className="page-toolbar">
        <input
          type="search"
          placeholder="Search users..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="search-input"
        />
        <button className="btn-primary">+ Add User</button>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((user) => (
              <tr key={user.id}>
                <td>{user.name}</td>
                <td>{user.email}</td>
                <td>{user.role}</td>
                <td>
                  <span className={`status-badge ${statusClass[user.status]}`}>
                    {user.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <p className="empty-state">No users match your search.</p>
        )}
      </div>
    </div>
  );
}

export default Users;
