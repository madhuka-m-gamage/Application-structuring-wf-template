/**
 * Tasks API route handlers conforming to contracts/api/openapi.yaml
 */
const crypto = require('crypto');
const db = require('../db');
const pubsub = require('../pubsub');

function sendProblem(res, status, title, detail, instance) {
  res.writeHead(status, { 'Content-Type': 'application/problem+json' });
  res.end(
    JSON.stringify({
      type: `https://api.system.template/errors/${status}`,
      title,
      status,
      detail,
      instance,
      timestamp: new Date().toISOString(),
    })
  );
}

function sendJson(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

async function listTasks(req, res, parsedUrl) {
  try {
    const statusParam = parsedUrl.searchParams.get('status');
    const limit = Math.min(parseInt(parsedUrl.searchParams.get('limit') || '50', 10), 100);
    const offset = Math.max(parseInt(parsedUrl.searchParams.get('offset') || '0', 10), 0);

    let queryText = 'SELECT * FROM tasks';
    const params = [];

    if (statusParam) {
      queryText += ' WHERE status = $1';
      params.push(statusParam);
    }

    queryText += ` ORDER BY created_at DESC LIMIT ${limit} OFFSET ${offset}`;

    const result = await db.query(queryText, params);
    sendJson(res, 200, {
      items: result.rows,
      count: result.rows.length,
      limit,
      offset,
    });
  } catch (err) {
    sendProblem(res, 500, 'Internal Server Error', err.message, parsedUrl.pathname);
  }
}

async function getTaskById(req, res, taskId, pathname) {
  try {
    const result = await db.query('SELECT * FROM tasks WHERE id = $1', [taskId]);
    if (!result.rows || result.rows.length === 0) {
      return sendProblem(res, 404, 'Task Not Found', `Task with ID ${taskId} does not exist`, pathname);
    }
    sendJson(res, 200, result.rows[0]);
  } catch (err) {
    sendProblem(res, 500, 'Internal Server Error', err.message, pathname);
  }
}

async function createTask(req, res, body, pathname) {
  try {
    if (!body || typeof body !== 'object') {
      return sendProblem(res, 400, 'Bad Request', 'Request body must be a valid JSON object', pathname);
    }

    const { title, description, priority = 'MEDIUM', payload = {}, userId } = body;

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return sendProblem(res, 422, 'Validation Error', 'Field "title" is required and cannot be empty', pathname);
    }

    const validPriorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    if (priority && !validPriorities.includes(priority.toUpperCase())) {
      return sendProblem(
        res,
        422,
        'Validation Error',
        `Field "priority" must be one of: ${validPriorities.join(', ')}`,
        pathname
      );
    }

    const taskId = crypto.randomUUID();
    const effectiveUserId = userId || '00000000-0000-0000-0000-000000000001';
    const taskStatus = 'QUEUED';

    // 1. Insert task into tasks table
    const insertTaskSql = `
      INSERT INTO tasks (id, user_id, title, description, priority, payload, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const taskResult = await db.query(insertTaskSql, [
      taskId,
      effectiveUserId,
      title.trim(),
      description ? description.trim() : null,
      priority.toUpperCase(),
      JSON.stringify(payload),
      taskStatus,
    ]);

    const createdTask = taskResult.rows[0] || {
      id: taskId,
      user_id: effectiveUserId,
      title: title.trim(),
      description,
      priority: priority.toUpperCase(),
      payload,
      status: taskStatus,
      created_at: new Date().toISOString(),
    };

    // 2. Transactional outbox pattern: stage event
    const eventType = 'com.system.task.created.v1';
    const eventPayload = {
      taskId,
      userId: effectiveUserId,
      title: createdTask.title,
      priority: createdTask.priority,
      actionPayload: payload,
      createdAt: createdTask.created_at,
    };

    await db.query(
      `INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, payload, status)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [crypto.randomUUID(), 'task', taskId, eventType, JSON.stringify(eventPayload), 'PENDING']
    );

    // 3. Publish directly to Cloud Pub/Sub emulator topic "tasks"
    const topicName = process.env.PUBSUB_TOPIC_TASKS || 'tasks';
    await pubsub.publishEvent(topicName, eventType, eventPayload);

    sendJson(res, 201, createdTask);
  } catch (err) {
    sendProblem(res, 500, 'Internal Server Error', err.message, pathname);
  }
}

async function deleteTask(req, res, taskId, pathname) {
  try {
    const result = await db.query('DELETE FROM tasks WHERE id = $1 RETURNING id', [taskId]);
    if (!result.rows || result.rows.length === 0) {
      return sendProblem(res, 404, 'Task Not Found', `Task with ID ${taskId} does not exist`, pathname);
    }
    res.writeHead(204);
    res.end();
  } catch (err) {
    sendProblem(res, 500, 'Internal Server Error', err.message, pathname);
  }
}

module.exports = {
  listTasks,
  getTaskById,
  createTask,
  deleteTask,
};
