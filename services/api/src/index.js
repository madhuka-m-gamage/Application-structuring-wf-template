/**
 * API Service Entrypoint
 * Listens on PORT (default 8080) and handles REST endpoints.
 */
const http = require('http');
const { handleHealthz } = require('./routes/health');
const { listTasks, getTaskById, createTask, deleteTask } = require('./routes/tasks');
const db = require('./db');

const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = process.env.HOST || '0.0.0.0';

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 1e6) {
        // 1MB max body size
        req.destroy();
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!body.trim()) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (e) {
        reject(new Error('Invalid JSON payload'));
      }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  // Common CORS headers for local development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Idempotency-Key');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  try {
    // Health probe
    if (pathname === '/healthz' && req.method === 'GET') {
      return await handleHealthz(req, res);
    }

    // Tasks collection: GET /api/v1/tasks, POST /api/v1/tasks
    if (pathname === '/api/v1/tasks') {
      if (req.method === 'GET') {
        return await listTasks(req, res, parsedUrl);
      }
      if (req.method === 'POST') {
        const body = await readJsonBody(req);
        return await createTask(req, res, body, pathname);
      }
    }

    // Task item: GET /api/v1/tasks/:id, DELETE /api/v1/tasks/:id
    const taskMatch = pathname.match(/^\/api\/v1\/tasks\/([a-zA-Z0-9_-]+)$/);
    if (taskMatch) {
      const taskId = taskMatch[1];
      if (req.method === 'GET') {
        return await getTaskById(req, res, taskId, pathname);
      }
      if (req.method === 'DELETE') {
        return await deleteTask(req, res, taskId, pathname);
      }
    }

    // Default 404
    res.writeHead(404, { 'Content-Type': 'application/problem+json' });
    res.end(
      JSON.stringify({
        type: 'https://api.system.template/errors/404',
        title: 'Not Found',
        status: 404,
        detail: `Path ${pathname} not recognized`,
        instance: pathname,
      })
    );
  } catch (err) {
    console.error(`[API Error] ${err.message}`, err.stack);
    res.writeHead(500, { 'Content-Type': 'application/problem+json' });
    res.end(
      JSON.stringify({
        type: 'https://api.system.template/errors/500',
        title: 'Internal Server Error',
        status: 500,
        detail: err.message,
        instance: pathname,
      })
    );
  }
});

server.listen(PORT, HOST, () => {
  console.log(`[API Service] Listening on http://${HOST}:${PORT}`);
});

// Graceful shutdown handling
function shutdown(signal) {
  console.log(`[API Service] Received ${signal}. Draining connections...`);
  server.close(async () => {
    await db.close();
    console.log('[API Service] Clean shutdown complete.');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('[API Service] Forced termination after timeout.');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = server;
