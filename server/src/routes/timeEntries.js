const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const VALID_CATEGORIES = [
  'Client Communication',
  'Client Meetings',
  'Client Operations',
  'Freelancer Support',
  'Resource Management',
  'Run Closure',
  'Run Preparation',
  'Test Management',
];

const timeEntrySchema = {
  project_id: { required: true, type: 'number' },
  description: { required: true, type: 'string' },
  start_time: { required: true, type: 'string' },
  end_time: { required: false, type: 'string' },
  category: { required: true, type: 'string' },
  is_billable: { required: false, type: 'boolean' },
  is_billed: { required: false, type: 'boolean' },
  is_logged: { required: false, type: 'boolean' },
};

// GET /api/time-entries - List all time entries (filter by project_id, category, is_billable)
router.get('/', (req, res) => {
  const db = getDb();
  const { project_id, category, is_billable } = req.query;

  let sql = 'SELECT * FROM time_entries WHERE 1=1';
  const params = [];

  if (project_id) {
    sql += ' AND project_id = ?';
    params.push(project_id);
  }
  if (category) {
    sql += ' AND category = ?';
    params.push(category);
  }
  if (is_billable !== undefined) {
    sql += ' AND is_billable = ?';
    params.push(is_billable === 'true' ? 1 : 0);
  }

  sql += ' ORDER BY start_time DESC';
  const entries = db.prepare(sql).all(...params);
  res.json(entries);
});

// GET /api/time-entries/:id - Get a single time entry
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const entry = db.prepare('SELECT * FROM time_entries WHERE id = ?').get(req.params.id);
  if (!entry) return next(ApiError.notFound('Time entry not found'));
  res.json(entry);
});

// POST /api/time-entries - Create a new time entry
router.post('/', validate(timeEntrySchema), (req, res, next) => {
  const db = getDb();
  const { project_id, description, start_time, end_time, category, is_billable, is_billed, is_logged } = req.body;

  if (!VALID_CATEGORIES.includes(category)) {
    return next(ApiError.badRequest(`Invalid category. Must be one of: ${VALID_CATEGORIES.join(', ')}`));
  }

  const project = db.prepare('SELECT id FROM projects WHERE id = ?').get(project_id);
  if (!project) return next(ApiError.badRequest('Project not found'));

  const result = db
    .prepare(
      `INSERT INTO time_entries (project_id, description, start_time, end_time, category, is_billable, is_billed, is_logged)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      project_id,
      description,
      start_time,
      end_time || null,
      category,
      is_billable !== false ? 1 : 0,
      is_billed ? 1 : 0,
      is_logged ? 1 : 0
    );

  const entry = db.prepare('SELECT * FROM time_entries WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(entry);
});

// PUT /api/time-entries/:id - Update a time entry
router.put('/:id', validate(timeEntrySchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM time_entries WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Time entry not found'));

  const { project_id, description, start_time, end_time, category, is_billable, is_billed, is_logged } = req.body;

  if (!VALID_CATEGORIES.includes(category)) {
    return next(ApiError.badRequest(`Invalid category. Must be one of: ${VALID_CATEGORIES.join(', ')}`));
  }

  const project = db.prepare('SELECT id FROM projects WHERE id = ?').get(project_id);
  if (!project) return next(ApiError.badRequest('Project not found'));

  db.prepare(
    `UPDATE time_entries SET project_id = ?, description = ?, start_time = ?, end_time = ?,
     category = ?, is_billable = ?, is_billed = ?, is_logged = ?
     WHERE id = ?`
  ).run(
    project_id,
    description,
    start_time,
    end_time || null,
    category,
    is_billable !== false ? 1 : 0,
    is_billed ? 1 : 0,
    is_logged ? 1 : 0,
    req.params.id
  );

  const entry = db.prepare('SELECT * FROM time_entries WHERE id = ?').get(req.params.id);
  res.json(entry);
});

// DELETE /api/time-entries/:id - Delete a time entry
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM time_entries WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Time entry not found'));

  db.prepare('DELETE FROM time_entries WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
