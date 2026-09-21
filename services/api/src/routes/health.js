/**
 * Health check probe route handler conforming to contracts/api/openapi.yaml
 */
const db = require('../db');
const pubsub = require('../pubsub');

const startTime = Date.now();

async function handleHealthz(req, res) {
  const dbHealth = await db.checkHealth();
  const pubsubHealth = await pubsub.checkHealth();

  const isDegraded = dbHealth.status === 'degraded' || pubsubHealth.status === 'degraded';
  const overallStatus = isDegraded ? 'degraded' : 'healthy';

  const responseBody = {
    status: overallStatus,
    version: process.env.SERVICE_VERSION || '1.0.0',
    timestamp: new Date().toISOString(),
    uptime: Number(((Date.now() - startTime) / 1000).toFixed(2)),
    checks: {
      database: dbHealth.status,
      database_mode: dbHealth.mode,
      pubsub: pubsubHealth.status,
      pubsub_mode: pubsubHealth.mode,
    },
  };

  const statusCode = overallStatus === 'unhealthy' ? 503 : 200;
  res.writeHead(statusCode, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(responseBody, null, 2));
}

module.exports = {
  handleHealthz,
};
