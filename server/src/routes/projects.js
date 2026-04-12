const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const projectSchema = {
  client_id: { required: true, type: 'number' },
  name: { required: true, type: 'string' },
  hourly_rate: { required: true, type: 'number' },
  monthly_time_limit: { required: false, type: 'number' },
  status: { required: false, type: 'string' },
};

// GET /api/projects - List all projects (optionally filter by client_id)
router.get('/', (req, res) => {
  const db = getDb();
  const { client_id } = req.query;
  let projects;

  if (client_id) {
    projects = db
      .prepare('SELECT * FROM projects WHERE client_id = ? ORDER BY name')
      .all(client_id);
  } else {
    projects = db.prepare('SELECT * FROM projects ORDER BY name').all();
  }

  res.json(projects);
});

// GET /api/projects/:id - Get a single project
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!project) return next(ApiError.notFound('Project not found'));
  res.json(project);
});

// POST /api/projects - Create a new project
router.post('/', validate(projectSchema), (req, res, next) => {
  const db = getDb();
  const { client_id, name, hourly_rate, monthly_time_limit, status } = req.body;

  // Verify parent client exists
  const client = db.prepare('SELECT id FROM clients WHERE id = ?').get(client_id);
  if (!client) return next(ApiError.badRequest('Client not found'));

  const result = db
    .prepare(
      `INSERT INTO projects (client_id, name, hourly_rate, monthly_time_limit, status)
       VALUES (?, ?, ?, ?, ?)`
    )
    .run(client_id, name, hourly_rate, monthly_time_limit || null, status || 'Active');

  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(project);
});

// PUT /api/projects/:id - Update a project
router.put('/:id', validate(projectSchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Project not found'));

  const { client_id, name, hourly_rate, monthly_time_limit, status } = req.body;

  const client = db.prepare('SELECT id FROM clients WHERE id = ?').get(client_id);
  if (!client) return next(ApiError.badRequest('Client not found'));

  db.prepare(
    `UPDATE projects SET client_id = ?, name = ?, hourly_rate = ?, monthly_time_limit = ?, status = ?
     WHERE id = ?`
  ).run(client_id, name, hourly_rate, monthly_time_limit || null, status || 'Active', req.params.id);

  const project = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  res.json(project);
});

// DELETE /api/projects/:id - Delete a project
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM projects WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Project not found'));

  db.prepare('DELETE FROM projects WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
