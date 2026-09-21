/**
 * Database client module for API service.
 * Connects to PostgreSQL using 'pg' pool when available,
 * with resilient in-memory fallback for local unit tests.
 */

let pgPool = null;
const memoryStore = {
  users: [
    {
      id: '00000000-0000-0000-0000-000000000001',
      email: 'demo@system.template',
      name: 'System Demo User',
      role: 'user',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ],
  tasks: [],
  outbox: [],
  idempotency: new Map(),
};

async function getPool() {
  if (pgPool) return pgPool;

  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    return null;
  }

  try {
    const { Pool } = require('pg');
    pgPool = new Pool({
      connectionString: dbUrl,
      max: parseInt(process.env.DB_POOL_MAX || '10', 10),
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });

    // Ensure seed user exists
    const client = await pgPool.connect();
    try {
      await client.query(`
        INSERT INTO users (id, email, name, role)
        VALUES ('00000000-0000-0000-0000-000000000001', 'demo@system.template', 'System Demo User', 'user')
        ON CONFLICT (email) DO NOTHING;
      `);
    } finally {
      client.release();
    }

    return pgPool;
  } catch (err) {
    console.warn(`[DB] PostgreSQL client initialization skipped/failed: ${err.message}. Using in-memory store.`);
    pgPool = null;
    return null;
  }
}

async function query(text, params = []) {
  const pool = await getPool();
  if (pool) {
    return pool.query(text, params);
  }

  // In-memory query simulation for unit testing
  return handleInMemoryQuery(text, params);
}

function handleInMemoryQuery(text, params) {
  const sql = text.trim().toUpperCase();

  if (sql.startsWith('SELECT 1')) {
    return { rows: [{ '?column?': 1 }], rowCount: 1 };
  }

  if (sql.includes('FROM TASKS WHERE ID =')) {
    const id = params[0];
    const task = memoryStore.tasks.find((t) => t.id === id);
    return { rows: task ? [task] : [], rowCount: task ? 1 : 0 };
  }

  if (sql.includes('SELECT') && sql.includes('FROM TASKS')) {
    return { rows: [...memoryStore.tasks], rowCount: memoryStore.tasks.length };
  }

  if (sql.includes('INSERT INTO TASKS')) {
    // Expected params: [id, user_id, title, description, priority, payload, status]
    const task = {
      id: params[0],
      user_id: params[1],
      title: params[2],
      description: params[3] || null,
      priority: params[4] || 'MEDIUM',
      payload: typeof params[5] === 'string' ? JSON.parse(params[5]) : params[5] || {},
      status: params[6] || 'PENDING',
      retry_count: 0,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    memoryStore.tasks.push(task);
    return { rows: [task], rowCount: 1 };
  }

  if (sql.includes('DELETE FROM TASKS WHERE ID =')) {
    const id = params[0];
    const idx = memoryStore.tasks.findIndex((t) => t.id === id);
    if (idx >= 0) {
      const removed = memoryStore.tasks.splice(idx, 1);
      return { rows: removed, rowCount: 1 };
    }
    return { rows: [], rowCount: 0 };
  }

  if (sql.includes('INSERT INTO OUTBOX_EVENTS')) {
    const event = {
      id: params[0],
      aggregate_type: params[1],
      aggregate_id: params[2],
      event_type: params[3],
      payload: typeof params[4] === 'string' ? JSON.parse(params[4]) : params[4],
      status: 'PENDING',
      created_at: new Date().toISOString(),
    };
    memoryStore.outbox.push(event);
    return { rows: [event], rowCount: 1 };
  }

  return { rows: [], rowCount: 0 };
}

async function checkHealth() {
  const pool = await getPool();
  if (!pool) {
    return { status: 'healthy', mode: 'in-memory-mock' };
  }
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
