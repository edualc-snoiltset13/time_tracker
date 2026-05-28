# Inventory & Sales Management System

A full-stack application for managing product inventory and tracking sales, built with **Flask** (Python) and **React**.

## Features

- **JWT Authentication** — Secure login/register with token-based auth
- **Role-Based Access Control** — Admin and Sales Agent roles
  - **Admin**: Full CRUD on products, view all sales and analytics
  - **Sales Agent**: View products, create sales, view own sales/analytics
- **Product Management** — Create, read, update, delete products with search/filter
- **Sales Tracking** — Create sales with multi-item line items, automatic inventory decrement
- **Dashboard** — Revenue KPIs, sales-over-time chart, top products bar chart, agent pie chart
- **REST API** — Clean, versioned API with validation and error handling
- **38 Unit Tests** — Comprehensive backend test coverage

---

## Project Structure

```
backend/
├── app.py                 # Flask app factory
├── config.py              # Configuration classes
├── extensions.py          # Shared Flask extensions (db, jwt, ma)
├── schemas.py             # Marshmallow validation schemas
├── seed.py                # Database seeder with sample data
├── requirements.txt       # Python dependencies
├── models/
│   ├── user.py            # User model with password hashing
│   ├── product.py         # Product model
│   └── sale.py            # Sale + SaleItem models
├── routes/
│   ├── auth.py            # Register, login, profile endpoints
│   ├── products.py        # Product CRUD endpoints
│   ├── sales.py           # Sales endpoints
│   └── dashboard.py       # Analytics/dashboard endpoints
├── middleware/
│   └── auth.py            # admin_required decorator, get_current_user
└── tests/
    ├── conftest.py         # Pytest fixtures
    ├── test_auth.py        # Auth tests (10)
    ├── test_products.py    # Product CRUD tests (14)
    ├── test_sales.py       # Sales tests (9)
    └── test_dashboard.py   # Dashboard tests (5)

frontend/
├── package.json
├── public/index.html
└── src/
    ├── index.js            # Entry point with providers
    ├── index.css           # Global styles
    ├── App.js              # Routes and layout
    ├── context/
    │   └── AuthContext.js  # Auth state management (React Context)
    ├── services/
    │   └── api.js          # Axios instance with JWT interceptor
    ├── components/
    │   └── Sidebar.js      # Navigation sidebar
    └── pages/
        ├── Login.js        # Login page
        ├── Register.js     # Registration page
        ├── Dashboard.js    # Analytics dashboard with charts
        ├── Products.js     # Product list with CRUD modals
        ├── Sales.js        # Sales list with expandable details
        └── NewSale.js      # Create new sale form
```

---

## Setup Instructions

### Prerequisites

- Python 3.10+
- Node.js 18+
- npm or yarn

### Backend Setup

```bash
cd backend

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate   # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file (copy from example)
cp .env.example .env
# Edit .env and set your own SECRET_KEY and JWT_SECRET_KEY

# Seed the database with sample data
python seed.py

# Run the development server
python app.py
```

The API will be available at `http://localhost:5000`.

#### Default Seed Users

| Username | Password   | Role        |
| -------- | ---------- | ----------- |
| admin    | admin123   | admin       |
| alice    | alice123   | sales_agent |
| bob      | bob123     | sales_agent |

### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start the development server
npm start
```

The frontend will be available at `http://localhost:3000`.

### Running Tests

```bash
cd backend
python -m pytest tests/ -v
```

---

## API Endpoints

### Authentication

| Method | Endpoint           | Description          | Auth     |
| ------ | ------------------ | -------------------- | -------- |
| POST   | /api/auth/register | Register new user    | None     |
| POST   | /api/auth/login    | Login, get JWT token | None     |
| GET    | /api/auth/me       | Get current profile  | Required |

### Products

| Method | Endpoint                 | Description             | Auth       |
| ------ | ------------------------ | ----------------------- | ---------- |
| GET    | /api/products            | List products (search, filter, paginate) | Required |
| GET    | /api/products/:id        | Get product by ID       | Required   |
| POST   | /api/products            | Create product          | Admin only |
| PUT    | /api/products/:id        | Update product          | Admin only |
| DELETE | /api/products/:id        | Delete product          | Admin only |
| GET    | /api/products/categories | List distinct categories| Required   |

### Sales

| Method | Endpoint         | Description                             | Auth     |
| ------ | ---------------- | --------------------------------------- | -------- |
| POST   | /api/sales       | Create sale (decrements inventory)      | Required |
| GET    | /api/sales       | List sales (admins: all, agents: own)   | Required |
| GET    | /api/sales/:id   | Get sale details                        | Required |

### Dashboard

| Method | Endpoint                      | Description                | Auth     |
| ------ | ----------------------------- | -------------------------- | -------- |
| GET    | /api/dashboard/summary        | KPIs: revenue, counts      | Required |
| GET    | /api/dashboard/sales-over-time| Daily revenue (last N days)| Required |
| GET    | /api/dashboard/top-products   | Top products by units sold | Required |
| GET    | /api/dashboard/sales-by-agent | Revenue breakdown by agent | Required |

---

## Database Schema

### Users
- `id` (PK), `username` (unique), `email` (unique), `password_hash`, `role` (admin/sales_agent), `created_at`

### Products
- `id` (PK), `name`, `sku` (unique), `description`, `price`, `quantity`, `category`, `created_at`, `updated_at`

### Sales
- `id` (PK), `agent_id` (FK -> users), `total_amount`, `status`, `created_at`

### Sale Items
- `id` (PK), `sale_id` (FK -> sales), `product_id` (FK -> products), `quantity`, `unit_price`, `subtotal`
