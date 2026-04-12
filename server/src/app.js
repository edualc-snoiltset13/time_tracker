const express = require('express');
const cors = require('cors');
const logger = require('./middleware/logger');
const { errorHandler } = require('./middleware/errorHandler');

// Route modules
const clientsRouter = require('./routes/clients');
const projectsRouter = require('./routes/projects');
const timeEntriesRouter = require('./routes/timeEntries');
const expensesRouter = require('./routes/expenses');
const invoicesRouter = require('./routes/invoices');
const todosRouter = require('./routes/todos');
const companySettingsRouter = require('./routes/companySettings');

const app = express();

// ---------------------------------------------------------------------------
// Global Middleware
// ---------------------------------------------------------------------------

// Enable CORS for all origins (configure as needed for production)
app.use(cors());

// Parse JSON request bodies
app.use(express.json());

// Log every request
app.use(logger);

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------

app.use('/api/clients', clientsRouter);
app.use('/api/projects', projectsRouter);
app.use('/api/time-entries', timeEntriesRouter);
app.use('/api/expenses', expensesRouter);
app.use('/api/invoices', invoicesRouter);
app.use('/api/todos', todosRouter);
app.use('/api/company-settings', companySettingsRouter);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ---------------------------------------------------------------------------
// 404 handler – must come after all route definitions
// ---------------------------------------------------------------------------
app.use((req, res) => {
  res.status(404).json({ error: { message: `Route ${req.method} ${req.originalUrl} not found` } });
});

// ---------------------------------------------------------------------------
// Centralized error handler – must be the last app.use()
// ---------------------------------------------------------------------------
app.use(errorHandler);

module.exports = app;
