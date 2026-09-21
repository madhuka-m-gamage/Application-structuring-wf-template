/**
 * Event processor implementing Pub/Sub CloudEvents consumption and idempotency.
 * Conforms to contracts/events/ standards.
 */
const crypto = require('crypto');
const db = require('./db');

async function checkAndRecordIdempotency(eventId, payloadHash) {
  const checkSql = 'SELECT key FROM idempotency_keys WHERE key = $1';
  const existing = await db.query(checkSql, [eventId]);
  if (existing.rows && existing.rows.length > 0) {
    return false; // Already processed
  }

  // Insert idempotency lock with 24-hour TTL
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const insertSql = `
    INSERT INTO idempotency_keys (key, request_hash, expires_at)
    VALUES ($1, $2, $3)
    ON CONFLICT (key) DO NOTHING
    RETURNING key;
  `;
  await db.query(insertSql, [eventId, payloadHash, expiresAt]);
  return true;
}

async function publishCompletionEvent(taskId, result) {
  const emulatorHost = process.env.PUBSUB_EMULATOR_HOST;
  const projectId = process.env.PUBSUB_PROJECT_ID || 'local-project';
  const topicName = process.env.PUBSUB_TOPIC_TASK_EVENTS || 'task-events';

  if (!emulatorHost) return;

  const eventPayload = {
    specversion: '1.0',
    id: crypto.randomUUID(),
    source: 'https://worker.system.template/tasks',
    type: 'com.system.task.completed.v1',
    time: new Date().toISOString(),
    datacontenttype: 'application/json',
    data: {
      taskId,
      status: 'COMPLETED',
      result,
      completedAt: new Date().toISOString(),
    },
  };

  try {
    const url = `http://${emulatorHost}/v1/projects/${projectId}/topics/${topicName}:publish`;
    const base64Data = Buffer.from(JSON.stringify(eventPayload)).toString('base64');
    await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        messages: [{ data: base64Data }],
      }),
    });
  } catch (err) {
    console.warn(`[Worker] Failed to publish completion event to PubSub emulator: ${err.message}`);
  }
}

async function processMessage(rawMessage) {
  let envelope = null;

  // 1. Unpack Pub/Sub push subscription envelope or direct payload
  if (rawMessage && rawMessage.message && rawMessage.message.data) {
    const decodedStr = Buffer.from(rawMessage.message.data, 'base64').toString('utf-8');
    try {
      envelope = JSON.parse(decodedStr);
    } catch (err) {
      throw new Error(`Poison pill: Failed to parse base64 JSON payload: ${err.message}`);
    }
  } else if (rawMessage && rawMessage.specversion && rawMessage.id) {
    // Direct CloudEvents envelope
    envelope = rawMessage;
  } else {
    throw new Error('Poison pill: Incoming payload is missing CloudEvents message structure');
  }

  // 2. Validate envelope structure
  if (!envelope.id || !envelope.type || !envelope.data) {
    throw new Error('Poison pill: CloudEvent missing required fields (id, type, data)');
  }

  const eventId = envelope.id;
  const eventType = envelope.type;
  const eventData = envelope.data;

  // 3. Idempotency Check
  const payloadHash = crypto.createHash('sha256').update(JSON.stringify(eventData)).digest('hex');
  const isNew = await checkAndRecordIdempotency(eventId, payloadHash);

  if (!isNew) {
    console.log(`[Worker] Duplicate event ${eventId} detected. Skipping execution (Idempotent ACK).`);
    return { status: 'duplicate_skipped', eventId };
  }

  console.log(`[Worker] Processing event ${eventId} of type ${eventType}`);

  // 4. Handle known event types
  if (eventType === 'com.system.task.created.v1') {
    const taskId = eventData.taskId;
    if (!taskId) {
      throw new Error('Poison pill: Task created event missing taskId');
    }

    // Step A: Mark task PROCESSING
    await db.query('UPDATE tasks SET status = $1 WHERE id = $2', ['PROCESSING', taskId]);

    // Step B: Simulate business execution workload
    const startTime = Date.now();
    await new Promise((resolve) => setTimeout(resolve, 50));
    const durationMs = Date.now() - startTime;

    const result = {
      outcome: 'SUCCESS',
      workerInstance: process.env.HOSTNAME || 'local-worker',
      durationMs,
      processedAt: new Date().toISOString(),
      actionEcho: eventData.actionPayload || {},
    };

    // Step C: Mark task COMPLETED
    await db.query(
      `UPDATE tasks 
       SET status = $1, result = $2, completed_at = CURRENT_TIMESTAMP 
       WHERE id = $3`,
      ['COMPLETED', JSON.stringify(result), taskId]
    );

    // Step D: Publish completion event
    await publishCompletionEvent(taskId, result);

    console.log(`[Worker] Task ${taskId} successfully executed and marked COMPLETED.`);
    return { status: 'completed', taskId, eventId };
  }

  // Unsupported event type
  console.warn(`[Worker] Unhandled event type: ${eventType}`);
  return { status: 'unhandled_type', eventType, eventId };
}

module.exports = {
  processMessage,
  checkAndRecordIdempotency,
};
