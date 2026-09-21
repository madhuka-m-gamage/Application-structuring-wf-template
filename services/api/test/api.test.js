const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');

let server;
let baseUrl;

before(async () => {
  // Use port 0 for random free port in test
  process.env.PORT = '0';
  process.env.DATABASE_URL = ''; // Force in-memory mock
  server = require('../src/index');

  await new Promise((resolve) => {
    if (server.listening) return resolve();
    server.on('listening', resolve);
  });

  const address = server.address();
  baseUrl = `http://127.0.0.1:${address.port}`;
});

after(async () => {
  if (server) {
    await new Promise((resolve) => server.close(resolve));
  }
});

async function request(path, options = {}) {
  const url = `${baseUrl}${path}`;
  const response = await fetch(url, options);
  const text = await response.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (e) {
    // not JSON
  }
  return { status: response.status, headers: response.headers, body: json, text };
}

test('GET /healthz returns 200 and schema compliant health check', async () => {
  const res = await request('/healthz');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'healthy');
  assert.ok(typeof res.body.uptime === 'number');
  assert.ok(res.body.timestamp);
  assert.ok(res.body.checks);
});

test('POST /api/v1/tasks creates a task with valid payload', async () => {
  const payload = {
    title: 'Process Ingestion Batch #42',
    description: 'Automated test task',
    priority: 'HIGH',
    payload: { batchId: 42, records: 100 },
  };

  const res = await request('/api/v1/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  assert.equal(res.status, 201);
  assert.ok(res.body.id);
  assert.equal(res.body.title, payload.title);
  assert.equal(res.body.priority, 'HIGH');
  assert.equal(res.body.status, 'QUEUED');
});

test('POST /api/v1/tasks rejects missing title with 422 Problem Details', async () => {
  const res = await request('/api/v1/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ priority: 'LOW' }),
  });

  assert.equal(res.status, 422);
  assert.equal(res.body.status, 422);
  assert.equal(res.body.title, 'Validation Error');
});

test('POST /api/v1/tasks rejects invalid priority with 422 Problem Details', async () => {
  const res = await request('/api/v1/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'Task with bad priority', priority: 'ULTRA_MAX' }),
  });

  assert.equal(res.status, 422);
  assert.equal(res.body.status, 422);
});

test('GET /api/v1/tasks returns list of tasks', async () => {
  const res = await request('/api/v1/tasks');
  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.items));
  assert.ok(res.body.count >= 1);
});

test('GET /api/v1/tasks/:id retrieves task and DELETE removes it', async () => {
  // Create task
  const createRes = await request('/api/v1/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: 'Temporary task for deletion' }),
  });
  const taskId = createRes.body.id;

  // Retrieve task
  const getRes = await request(`/api/v1/tasks/${taskId}`);
  assert.equal(getRes.status, 200);
  assert.equal(getRes.body.id, taskId);

  // Delete task
  const delRes = await request(`/api/v1/tasks/${taskId}`, { method: 'DELETE' });
  assert.equal(delRes.status, 204);

  // Retrieve again -> 404
  const getAfterDel = await request(`/api/v1/tasks/${taskId}`);
  assert.equal(getAfterDel.status, 404);
});
