const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const clientSchema = {
  name: { required: true, type: 'string' },
  email: { required: false, type: 'string' },
  address: { required: false, type: 'string' },
  currency: { required: false, type: 'string' },
};

// GET /api/clients - List all clients
router.get('/', (req, res) => {
  const db = getDb();
  const clients = db.prepare('SELECT * FROM clients ORDER BY name').all();
  res.json(clients);
});

// GET /api/clients/:id - Get a single client
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.id);
  if (!client) return next(ApiError.notFound('Client not found'));
  res.json(client);
});

// POST /api/clients - Create a new client
router.post('/', validate(clientSchema), (req, res) => {
  const db = getDb();
  const { name, email, address, currency } = req.body;
  const result = db
    .prepare(
      'INSERT INTO clients (name, email, address, currency) VALUES (?, ?, ?, ?)'
    )
    .run(name, email || null, address || null, currency || 'USD');

  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(client);
});

// PUT /api/clients/:id - Update a client
router.put('/:id', validate(clientSchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Client not found'));

  const { name, email, address, currency } = req.body;
  db.prepare(
    'UPDATE clients SET name = ?, email = ?, address = ?, currency = ? WHERE id = ?'
  ).run(name, email || null, address || null, currency || 'USD', req.params.id);

  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.id);
  res.json(client);
});

// DELETE /api/clients/:id - Delete a client (cascades to projects, entries, etc.)
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Client not found'));

  db.prepare('DELETE FROM clients WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
