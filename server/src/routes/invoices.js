const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const invoiceSchema = {
  client_id: { required: true, type: 'number' },
  issue_date: { required: true, type: 'string' },
  due_date: { required: true, type: 'string' },
  total_amount: { required: true, type: 'number' },
  status: { required: true, type: 'string' },
  notes: { required: false, type: 'string' },
};

// GET /api/invoices - List all invoices (filter by client_id, status)
router.get('/', (req, res) => {
  const db = getDb();
  const { client_id, status } = req.query;

  let sql = 'SELECT * FROM invoices WHERE 1=1';
  const params = [];

  if (client_id) {
    sql += ' AND client_id = ?';
    params.push(client_id);
  }
  if (status) {
    sql += ' AND status = ?';
    params.push(status);
  }

  sql += ' ORDER BY issue_date DESC';
  const invoices = db.prepare(sql).all(...params);

  // Parse line_items_json for each invoice
  const result = invoices.map((inv) => ({
    ...inv,
    line_items: inv.line_items_json ? JSON.parse(inv.line_items_json) : [],
  }));

  res.json(result);
});

// GET /api/invoices/:id - Get a single invoice
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const invoice = db.prepare('SELECT * FROM invoices WHERE id = ?').get(req.params.id);
  if (!invoice) return next(ApiError.notFound('Invoice not found'));

  res.json({
    ...invoice,
    line_items: invoice.line_items_json ? JSON.parse(invoice.line_items_json) : [],
  });
});

// POST /api/invoices - Create a new invoice
router.post('/', validate(invoiceSchema), (req, res, next) => {
  const db = getDb();
  const { client_id, issue_date, due_date, total_amount, status, notes, line_items } = req.body;

  const client = db.prepare('SELECT id FROM clients WHERE id = ?').get(client_id);
  if (!client) return next(ApiError.badRequest('Client not found'));

  const invoice_id_string = `INV-${uuidv4().slice(0, 8).toUpperCase()}`;
  const line_items_json = line_items ? JSON.stringify(line_items) : null;

  const result = db
    .prepare(
      `INSERT INTO invoices (invoice_id_string, client_id, issue_date, due_date, total_amount, status, notes, line_items_json)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(invoice_id_string, client_id, issue_date, due_date, total_amount, status, notes || null, line_items_json);

  const invoice = db.prepare('SELECT * FROM invoices WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json({
    ...invoice,
    line_items: invoice.line_items_json ? JSON.parse(invoice.line_items_json) : [],
  });
});

// PUT /api/invoices/:id - Update an invoice
router.put('/:id', validate(invoiceSchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM invoices WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Invoice not found'));

  const { client_id, issue_date, due_date, total_amount, status, notes, line_items } = req.body;

  const client = db.prepare('SELECT id FROM clients WHERE id = ?').get(client_id);
  if (!client) return next(ApiError.badRequest('Client not found'));

  const line_items_json = line_items ? JSON.stringify(line_items) : existing.line_items_json;

  db.prepare(
    `UPDATE invoices SET client_id = ?, issue_date = ?, due_date = ?, total_amount = ?,
     status = ?, notes = ?, line_items_json = ?
     WHERE id = ?`
  ).run(client_id, issue_date, due_date, total_amount, status, notes || null, line_items_json, req.params.id);

  const invoice = db.prepare('SELECT * FROM invoices WHERE id = ?').get(req.params.id);
  res.json({
    ...invoice,
    line_items: invoice.line_items_json ? JSON.parse(invoice.line_items_json) : [],
  });
});

// DELETE /api/invoices/:id - Delete an invoice
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM invoices WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Invoice not found'));

  db.prepare('DELETE FROM invoices WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
