/**
 * Request logging middleware.
 * Logs method, URL, status code, and response time for every request.
 */
function logger(req, res, next) {
  const start = Date.now();
  const { method, originalUrl } = req;

  res.on('finish', () => {
    const duration = Date.now() - start;
    const { statusCode } = res;
    const timestamp = new Date().toISOString();
    console.log(
      `[${timestamp}] ${method} ${originalUrl} ${statusCode} - ${duration}ms`
    );
  });

  next();
}

module.exports = logger;
