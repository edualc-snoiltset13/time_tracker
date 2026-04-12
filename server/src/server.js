const app = require('./app');
const { closeDb } = require('./database/db');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`Time Tracker API server running on http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

// Graceful shutdown
function shutdown() {
  console.log('\nShutting down gracefully...');
  server.close(() => {
    closeDb();
    console.log('Server closed.');
    process.exit(0);
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
