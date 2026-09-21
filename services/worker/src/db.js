/**
 * Database client module for Worker service.
 * Supports PostgreSQL connection with resilient in-memory fallback for tests.
 */

let pgPool = null;
const memoryStore = {
  tasks: new Map(),
  idempotency: new Map(),
};

async function getPool() {
  if (pgPool) return pgPool;

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) return null;

  try {
    const { Pool } = require('pg');
    pgPool = new Pool({
      connectionString: dbUrl,
      max: parseInt(process.env.DB_POOL_MAX || '5', 10),
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
    return pgPool;
  } catch (err) {
    console.warn(`[Worker DB] PostgreSQL init skipped: ${err.message}. Using in-memory store.`);
    pgPool = null;
    return null;
  }
}

async function query(text, params = []) {
  const pool = await getPool();
  if (pool) {
    return pool.query(text, params);
  }

  return handleInMemoryQuery(text, params);
}

function handleInMemoryQuery(text, params) {
  const sql = text.trim().toUpperCase();

  if (sql.startsWith('SELECT 1')) {
    return { rows: [{ '?column?': 1 }], rowCount: 1 };
  }

  // Idempotency check: SELECT key FROM idempotency_keys WHERE key = $1
  if (sql.includes('FROM IDEMPOTENCY_KEYS WHERE KEY =')) {
    const key = params[0];
    const exists = memoryStore.idempotency.has(key);
    return { rows: exists ? [{ key }] : [], rowCount: exists ? 1 : 0 };
  }

  // Idempotency insert: INSERT INTO idempotency_keys (key, request_hash, expires_at)
  if (sql.includes('INSERT INTO IDEMPOTENCY_KEYS')) {
    const key = params[0];
    memoryStore.idempotency.set(key, {
      key,
      request_hash: params[1],
      expires_at: params[2],
      created_at: new Date().toISOString(),
    });
    return { rows: [{ key }], rowCount: 1 };
  }

  // Task update: UPDATE tasks SET status = ... WHERE id = ...
  if (sql.includes('UPDATE TASKS SET')) {
    const taskId = params[params.length - 1];
    const task = memoryStore.tasks.get(taskId) || { id: taskId };
    if (params[0]) task.status = params[0];
    if (params.length > 2 && params[1]) {
      task.result = typeof params[1] === 'string' ? JSON.parse(params[1]) : params[1];
    }
    task.updated_at = new Date().toISOString();
    memoryStore.tasks.set(taskId, task);
    return { rows: [task], rowCount: 1 };
  }

  return { rows: [], rowCount: 0 };
}

async function checkHealth() {
  const pool = await getPool();
  if (!pool) return { status: 'healthy', mode: 'in-memory-mock' };
  try {
    const res = await pool.query('SELECT 1 AS alive');
    return { status: res.rows[0].alive === 1 ? 'healthy' : 'unhealthy', mode: 'postgresql' };
  } catch (err) {
    return { status: 'degraded', mode: 'postgresql', error: err.message };
  }
}

async function close() {
  if (pgPool) {
    await pgPool.end();
    pgPool = null;
  }
}

module.exports = {
  getPool,
  query,
  checkHealth,
  close,
  memoryStore,
};
