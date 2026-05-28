import React, { useState } from "react";

function Settings() {
  const [form, setForm] = useState({
    name: "Admin User",
    email: "admin@example.com",
    notifications: true,
    darkMode: true,
    language: "en",
  });

  const handleChange = (field, value) => {
    setForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    alert("Settings saved!");
  };

  return (
    <div className="settings-page">
      <form onSubmit={handleSubmit}>
        <div className="card">
          <h3>Profile</h3>
          <div className="form-group">
            <label>Name</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => handleChange("name", e.target.value)}
            />
          </div>
          <div className="form-group">
            <label>Email</label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => handleChange("email", e.target.value)}
            />
          </div>
        </div>

        <div className="card">
          <h3>Preferences</h3>
          <div className="form-group toggle-group">
            <label>Email Notifications</label>
            <button
              type="button"
              className={`toggle ${form.notifications ? "on" : ""}`}
              onClick={() => handleChange("notifications", !form.notifications)}
            >
              <span className="toggle-knob" />
            </button>
          </div>
          <div className="form-group toggle-group">
            <label>Dark Mode</label>
            <button
              type="button"
              className={`toggle ${form.darkMode ? "on" : ""}`}
              onClick={() => handleChange("darkMode", !form.darkMode)}
            >
              <span className="toggle-knob" />
            </button>
          </div>
          <div className="form-group">
            <label>Language</label>
            <select
              value={form.language}
              onChange={(e) => handleChange("language", e.target.value)}
            >
              <option value="en">English</option>
              <option value="es">Spanish</option>
              <option value="fr">French</option>
              <option value="de">German</option>
            </select>
          </div>
        </div>

        <button type="submit" className="btn-primary">
          Save Settings
        </button>
      </form>
    </div>
  );
}

export default Settings;
