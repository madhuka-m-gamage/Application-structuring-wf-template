/**
 * Web Frontend Server
 * Serves SPA assets, proxies /api/* requests to the Backend API, and provides /healthz.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.env.PORT || '3000', 10);
const HOST = process.env.HOST || '0.0.0.0';
const API_URL = process.env.API_URL || 'http://api:8080';
const PUBLIC_DIR = path.join(__dirname, '..', 'public');
const startTime = Date.now();

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

async function proxyApiRequest(req, res, targetUrl) {
  try {
    const url = new URL(req.url, targetUrl);
    const headers = { ...req.headers };
    delete headers.host; // Let fetch handle Host header

    const bodyChunks = [];
    if (['POST', 'PUT', 'PATCH'].includes(req.method)) {
      for await (const chunk of req) {
        bodyChunks.push(chunk);
      }
    }
    const bodyBuffer = bodyChunks.length > 0 ? Buffer.concat(bodyChunks) : undefined;

    const proxyResponse = await fetch(url.toString(), {
      method: req.method,
      headers,
      body: bodyBuffer,
      redirect: 'manual',
    });

    const responseHeaders = {};
    for (const [key, value] of proxyResponse.headers.entries()) {
      responseHeaders[key] = value;
    }

    res.writeHead(proxyResponse.status, responseHeaders);
    const arrayBuf = await proxyResponse.arrayBuffer();
    res.end(Buffer.from(arrayBuf));
  } catch (err) {
    console.error(`[Web Proxy Error] Failed to proxy ${req.method} ${req.url} -> ${targetUrl}: ${err.message}`);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(
      JSON.stringify({
        error: 'Bad Gateway',
        message: `Failed to communicate with upstream API at ${targetUrl}`,
        detail: err.message,
      })
    );
  }
}

function serveStaticFile(res, filePath) {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      // Fallback to index.html for SPA client-side routing
      const indexPath = path.join(PUBLIC_DIR, 'index.html');
      fs.readFile(indexPath, (indexErr, indexData) => {
        if (indexErr) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          return res.end('404 Not Found');
        }
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(indexData);
      });
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = parsedUrl.pathname;

  // Liveness healthcheck probe
  if (pathname === '/healthz' && req.method === 'GET') {
    const responseBody = {
      status: 'healthy',
      service: 'web',
      version: process.env.SERVICE_VERSION || '1.0.0',
      uptime: Number(((Date.now() - startTime) / 1000).toFixed(2)),
      apiUrl: API_URL,
      timestamp: new Date().toISOString(),
    };
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify(responseBody, null, 2));
  }

  // Reverse proxy API routes to backend API
  if (pathname.startsWith('/api/') || pathname === '/api') {
    return await proxyApiRequest(req, res, API_URL);
  }

  // Static files & SPA
  let safePath = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
  if (safePath === '/' || safePath === '') {
    safePath = '/index.html';
  }
  const fullPath = path.join(PUBLIC_DIR, safePath);
  serveStaticFile(res, fullPath);
});

server.listen(PORT, HOST, () => {
  console.log(`[Web Service] Running on http://${HOST}:${PORT}`);
  console.log(`[Web Service] Proxying /api/* requests to ${API_URL}`);
});

function shutdown(signal) {
  console.log(`[Web Service] Received ${signal}. Shutting down...`);
  server.close(() => {
    console.log('[Web Service] Clean shutdown complete.');
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 5000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

module.exports = server;
