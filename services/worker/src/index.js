/**
 * Background Event Worker Service Entrypoint
 * Listens on PORT (default 8080) for Pub/Sub push subscription dispatches.
 */
const http = require('http');
const { processMessage } = require('./processor');
const db = require('./db');

const PORT = parseInt(process.env.PORT || '8080', 10);
const HOST = process.env.HOST || '0.0.0.0';
const startTime = Date.now();

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 2e6) {
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
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  // Liveness / readiness health probe
  if (pathname === '/healthz' && req.method === 'GET') {
    const dbHealth = await db.checkHealth();
    const responseBody = {
      status: dbHealth.status === 'unhealthy' ? 'unhealthy' : 'healthy',
      service: 'worker',
      version: process.env.SERVICE_VERSION || '1.0.0',
      uptime: Number(((Date.now() - startTime) / 1000).toFixed(2)),
      timestamp: new Date().toISOString(),
      checks: {
        database: dbHealth.status,
        database_mode: dbHealth.mode,
      },
    };
    res.writeHead(responseBody.status === 'unhealthy' ? 503 : 200, {
      'Content-Type': 'application/json',
    });
    return res.end(JSON.stringify(responseBody, null, 2));
  }

  // Cloud Pub/Sub Push Subscription endpoint
  if ((pathname === '/events/push' || pathname === '/') && req.method === 'POST') {
    try {
      const body = await readJsonBody(req);
      const outcome = await processMessage(body);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ status: 'ACK', outcome }));
    } catch (err) {
      console.error(`[Worker Error] ${err.message}`);
      if (err.message.startsWith('Poison pill:')) {
        // Return 200 to acknowledge and drop poison pill if DLQ is not intercepting,
        // or return 400 for bad request. Returning 400 will cause Pub/Sub to retry up to 5x then route to DLQ.
        res.writeHead(400, { 'Content-Type': 'application/json' });
        return res.end(JSON.stringify({ error: err.message, poisonPill: true }));
      }
      // Transient error: return 500 so Pub/Sub retries with backoff
      res.writeHead(500, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ error: 'Internal processing error, will retry' }));
    }
  }

  // Default 404
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: `Path ${pathname} not found on worker` }));
});

server.listen(PORT, HOST, () => {
  console.log(`[Worker Service] Listening for push events on http://${HOST}:${PORT}`);
});

function shutdown(signal) {
  console.log(`[Worker Service] Received ${signal}. Shutting down cleanly...`);
  server.close(async () => {
    await db.close();
    console.log('[Worker Service] Clean shutdown complete.');
    process.exit(0);
  });

  setTimeout(() => {
    console.error('[Worker Service] Forced exit on timeout.');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = server;
