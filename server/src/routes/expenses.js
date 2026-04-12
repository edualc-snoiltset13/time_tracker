const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const expenseSchema = {
  description: { required: true, type: 'string' },
  project_id: { required: false, type: 'number' },
  client_id: { required: false, type: 'number' },
  category: { required: true, type: 'string' },
  amount: { required: true, type: 'number' },
  date: { required: true, type: 'string' },
  distance: { required: false, type: 'number' },
  cost_per_unit: { required: false, type: 'number' },
  is_billed: { required: false, type: 'boolean' },
};

// GET /api/expenses - List all expenses (filter by project_id, client_id)
router.get('/', (req, res) => {
  const db = getDb();
  const { project_id, client_id } = req.query;

  let sql = 'SELECT * FROM expenses WHERE 1=1';
  const params = [];

  if (project_id) {
    sql += ' AND project_id = ?';
    params.push(project_id);
  }
  if (client_id) {
    sql += ' AND client_id = ?';
    params.push(client_id);
  }

  sql += ' ORDER BY date DESC';
  const expenses = db.prepare(sql).all(...params);
  res.json(expenses);
});

// GET /api/expenses/:id - Get a single expense
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const expense = db.prepare('SELECT * FROM expenses WHERE id = ?').get(req.params.id);
  if (!expense) return next(ApiError.notFound('Expense not found'));
  res.json(expense);
});

// POST /api/expenses - Create a new expense
router.post('/', validate(expenseSchema), (req, res) => {
  const db = getDb();
  const { description, project_id, client_id, category, amount, date, distance, cost_per_unit, is_billed } = req.body;

  const result = db
    .prepare(
      `INSERT INTO expenses (description, project_id, client_id, category, amount, date, distance, cost_per_unit, is_billed)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      description,
      project_id || null,
      client_id || null,
      category,
      amount,
      date,
      distance || null,
      cost_per_unit || null,
      is_billed ? 1 : 0
    );

  const expense = db.prepare('SELECT * FROM expenses WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(expense);
});

// PUT /api/expenses/:id - Update an expense
router.put('/:id', validate(expenseSchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM expenses WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Expense not found'));

  const { description, project_id, client_id, category, amount, date, distance, cost_per_unit, is_billed } = req.body;

  db.prepare(
    `UPDATE expenses SET description = ?, project_id = ?, client_id = ?, category = ?,
     amount = ?, date = ?, distance = ?, cost_per_unit = ?, is_billed = ?
     WHERE id = ?`
  ).run(
    description,
    project_id || null,
    client_id || null,
    category,
    amount,
    date,
    distance || null,
    cost_per_unit || null,
    is_billed ? 1 : 0,
    req.params.id
  );

  const expense = db.prepare('SELECT * FROM expenses WHERE id = ?').get(req.params.id);
  res.json(expense);
});

// DELETE /api/expenses/:id - Delete an expense
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM expenses WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Expense not found'));

  db.prepare('DELETE FROM expenses WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
