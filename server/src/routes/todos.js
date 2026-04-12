const express = require('express');
const { getDb } = require('../database/db');
const { ApiError } = require('../middleware/errorHandler');
const validate = require('../middleware/validate');

const router = express.Router();

const todoSchema = {
  title: { required: true, type: 'string' },
  description: { required: false, type: 'string' },
  project_id: { required: true, type: 'number' },
  category: { required: true, type: 'string' },
  deadline: { required: true, type: 'string' },
  priority: { required: true, type: 'string' },
  is_completed: { required: false, type: 'boolean' },
  start_time: { required: true, type: 'string' },
  estimated_hours: { required: false, type: 'number' },
};

// GET /api/todos - List all todos (filter by project_id, priority, is_completed)
router.get('/', (req, res) => {
  const db = getDb();
  const { project_id, priority, is_completed } = req.query;

  let sql = 'SELECT * FROM todos WHERE 1=1';
  const params = [];

  if (project_id) {
    sql += ' AND project_id = ?';
    params.push(project_id);
  }
  if (priority) {
    sql += ' AND priority = ?';
    params.push(priority);
  }
  if (is_completed !== undefined) {
    sql += ' AND is_completed = ?';
    params.push(is_completed === 'true' ? 1 : 0);
  }

  sql += ' ORDER BY deadline ASC';
  const todos = db.prepare(sql).all(...params);
  res.json(todos);
});

// GET /api/todos/:id - Get a single todo
router.get('/:id', (req, res, next) => {
  const db = getDb();
  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  if (!todo) return next(ApiError.notFound('Todo not found'));
  res.json(todo);
});

// POST /api/todos - Create a new todo
router.post('/', validate(todoSchema), (req, res, next) => {
  const db = getDb();
  const { title, description, project_id, category, deadline, priority, is_completed, start_time, estimated_hours } = req.body;

  const project = db.prepare('SELECT id FROM projects WHERE id = ?').get(project_id);
  if (!project) return next(ApiError.badRequest('Project not found'));

  const result = db
    .prepare(
      `INSERT INTO todos (title, description, project_id, category, deadline, priority, is_completed, start_time, estimated_hours)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .run(
      title,
      description || null,
      project_id,
      category,
      deadline,
      priority,
      is_completed ? 1 : 0,
      start_time,
      estimated_hours || null
    );

  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(result.lastInsertRowid);
  res.status(201).json(todo);
});

// PUT /api/todos/:id - Update a todo
router.put('/:id', validate(todoSchema), (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Todo not found'));

  const { title, description, project_id, category, deadline, priority, is_completed, start_time, estimated_hours } = req.body;

  const project = db.prepare('SELECT id FROM projects WHERE id = ?').get(project_id);
  if (!project) return next(ApiError.badRequest('Project not found'));

  db.prepare(
    `UPDATE todos SET title = ?, description = ?, project_id = ?, category = ?,
     deadline = ?, priority = ?, is_completed = ?, start_time = ?, estimated_hours = ?
     WHERE id = ?`
  ).run(
    title,
    description || null,
    project_id,
    category,
    deadline,
    priority,
    is_completed ? 1 : 0,
    start_time,
    estimated_hours || null,
    req.params.id
  );

  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  res.json(todo);
});

// PATCH /api/todos/:id/toggle - Toggle completion status
router.patch('/:id/toggle', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Todo not found'));

  const newStatus = existing.is_completed ? 0 : 1;
  db.prepare('UPDATE todos SET is_completed = ? WHERE id = ?').run(newStatus, req.params.id);

  const todo = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  res.json(todo);
});

// DELETE /api/todos/:id - Delete a todo
router.delete('/:id', (req, res, next) => {
  const db = getDb();
  const existing = db.prepare('SELECT * FROM todos WHERE id = ?').get(req.params.id);
  if (!existing) return next(ApiError.notFound('Todo not found'));

  db.prepare('DELETE FROM todos WHERE id = ?').run(req.params.id);
  res.status(204).end();
});

module.exports = router;
