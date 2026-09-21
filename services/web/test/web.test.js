const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

let webServer;
let mockApiServer;
let webBaseUrl;
let mockApiBaseUrl;

before(async () => {
  // Start mock upstream API server
  mockApiServer = http.createServer((req, res) => {
    if (req.url === '/api/v1/tasks') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end(JSON.stringify({ items: [{ id: 'mock-1', title: 'Mock Task' }] }));
    }
    res.writeHead(404);
    res.end();
  });

  await new Promise((resolve) => mockApiServer.listen(0, '127.0.0.1', resolve));
  const apiAddr = mockApiServer.address();
  mockApiBaseUrl = `http://127.0.0.1:${apiAddr.port}`;

  process.env.PORT = '0';
  process.env.API_URL = mockApiBaseUrl;
  webServer = require('../src/server');

  await new Promise((resolve) => {
    if (webServer.listening) return resolve();
    webServer.on('listening', resolve);
  });

  const webAddr = webServer.address();
  webBaseUrl = `http://127.0.0.1:${webAddr.port}`;
});

after(async () => {
  if (webServer) {
    await new Promise((resolve) => webServer.close(resolve));
  }
  if (mockApiServer) {
    await new Promise((resolve) => mockApiServer.close(resolve));
  }
});

async function request(path) {
  const res = await fetch(`${webBaseUrl}${path}`);
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (e) {}
  return { status: res.status, headers: res.headers, body: json, text };
}

test('GET /healthz returns 200 and healthy web service metadata', async () => {
  const res = await request('/healthz');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'healthy');
  assert.equal(res.body.service, 'web');
  assert.ok(typeof res.body.uptime === 'number');
});

test('GET / serves index.html single page application', async () => {
  const res = await request('/');
  assert.equal(res.status, 200);
  assert.ok(res.text.includes('Design-to-Deployment Dashboard'));
});

test('GET /style.css serves stylesheet with correct content type', async () => {
  const res = await request('/style.css');
  assert.equal(res.status, 200);
  assert.ok(res.headers.get('content-type').includes('text/css'));
  assert.ok(res.text.includes('--bg-main'));
});

test('GET /api/v1/tasks correctly proxies to upstream API', async () => {
  const res = await request('/api/v1/tasks');
  assert.equal(res.status, 200);
  assert.ok(res.body.items);
  assert.equal(res.body.items[0].id, 'mock-1');
});
