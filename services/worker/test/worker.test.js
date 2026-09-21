const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');

let server;
let baseUrl;

before(async () => {
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

test('GET /healthz on worker returns 200 and healthy status', async () => {
  const res = await request('/healthz');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'healthy');
  assert.equal(res.body.service, 'worker');
  assert.ok(typeof res.body.uptime === 'number');
});

test('POST /events/push processes task-created event and returns ACK', async () => {
  const eventId = crypto.randomUUID();
  const taskId = crypto.randomUUID();

  const cloudEvent = {
    specversion: '1.0',
    id: eventId,
    source: 'https://api.system.template/tasks',
    type: 'com.system.task.created.v1',
    time: new Date().toISOString(),
    datacontenttype: 'application/json',
    data: {
      taskId,
      userId: '00000000-0000-0000-0000-000000000001',
      title: 'Worker Pipeline Test',
      priority: 'HIGH',
      actionPayload: { action: 'process_dataset', count: 50 },
    },
  };

  const base64Data = Buffer.from(JSON.stringify(cloudEvent)).toString('base64');
  const pubsubMessage = {
    message: {
      attributes: { 'ce-type': 'com.system.task.created.v1' },
      data: base64Data,
      messageId: 'test-msg-12345',
    },
    subscription: 'projects/local-project/subscriptions/worker-task-created-sub',
  };

  const res = await request('/events/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pubsubMessage),
  });

  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'ACK');
  assert.equal(res.body.outcome.status, 'completed');
  assert.equal(res.body.outcome.taskId, taskId);
});

test('POST /events/push deduplicates replayed event with same ID (Idempotent ACK)', async () => {
  const eventId = crypto.randomUUID();
  const taskId = crypto.randomUUID();

  const cloudEvent = {
    specversion: '1.0',
    id: eventId,
    source: 'https://api.system.template/tasks',
    type: 'com.system.task.created.v1',
    data: { taskId, title: 'Idempotent Test' },
  };

  const base64Data = Buffer.from(JSON.stringify(cloudEvent)).toString('base64');
  const pubsubMessage = {
    message: { data: base64Data },
  };

  // First execution: should complete
  const firstRes = await request('/events/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pubsubMessage),
  });
  assert.equal(firstRes.status, 200);
  assert.equal(firstRes.body.outcome.status, 'completed');

  // Second execution (replay): should detect duplicate and skip side-effects
  const secondRes = await request('/events/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pubsubMessage),
  });
  assert.equal(secondRes.status, 200);
  assert.equal(secondRes.body.outcome.status, 'duplicate_skipped');
});

test('POST /events/push detects and flags poison pill payload with 400 Bad Request', async () => {
  const badMessage = {
    message: {
      data: Buffer.from('this is not valid json').toString('base64'),
    },
  };

  const res = await request('/events/push', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(badMessage),
  });

  assert.equal(res.status, 400);
  assert.ok(res.body.poisonPill);
});
