# Background Event Worker Service (`services/worker/`)

The **Background Event Worker** is the asynchronous processing container in the **System Design-to-Deployment Template**. Deployed as an event subscriber on **Google Cloud Run (v2)**, it consumes domain events pushed by **Google Cloud Pub/Sub**, executes compute workloads, enforces distributed idempotency, updates state in **PostgreSQL 16**, and publishes downstream lifecycle events.

---

## 1. Architectural Role & Standards

- **Runtime**: Node.js 20 LTS (Lightweight, Alpine multi-stage container)
- **Execution Context**: Unprivileged non-root user `appuser` (UID 10001)
- **Ingress Protocol**: HTTPS POST Push Subscription invoking `/events/push` (OIDC-authenticated in cloud)
- **Contract Reference**: Conforms to CloudEvents v1.0 specifications in [`contracts/events/`](../../contracts/events/)
- **Deduplication Engine**: Enforces distributed idempotency via the `idempotency_keys` table in PostgreSQL
- **Failure Quarantine**: Automatic Dead-Letter Queue (DLQ) routing to `tasks-dlq` after 5 consecutive delivery attempts

---

## 2. Event Consumption Flow

```mermaid
sequenceDiagram
    autonumber
    participant PS as Google Cloud Pub/Sub
    participant W as Worker (/events/push)
    participant DB as PostgreSQL (Cloud SQL)
    participant DLQ as Pub/Sub DLQ (tasks-dlq)

    PS->>W: POST /events/push (CloudEvent wrapped in base64)
    W->>W: 1. Decode base64 payload & validate CloudEvents envelope
    W->>DB: 2. Query idempotency_keys for event ID
    alt Duplicate Event Detected
        W-->>PS: 200 OK (Idempotent ACK, skip execution)
    else First-Time Execution
        W->>DB: 3. Insert idempotency lock (TTL: 24h)
        W->>DB: 4. UPDATE tasks SET status = 'PROCESSING'
        W->>W: 5. Execute domain task workload
        W->>DB: 6. UPDATE tasks SET status = 'COMPLETED', result = {...}
        W->>PS: 7. Publish com.system.task.completed.v1 to 'task-events'
        W-->>PS: 200 OK (Message Processed ACK)
    end
    opt Poison Pill (Unrecoverable Payload Syntax Error)
        W-->>PS: 400 Bad Request
        PS->>DLQ: Route to tasks-dlq after 5 retries
    end
```

---

## 3. Endpoints

| Method | Path | Description | Security |
|---|---|---|---|
| `GET` | `/healthz` | Health, uptime, and database connection probe | Public |
| `POST` | `/events/push` | Cloud Pub/Sub push subscription delivery endpoint | OIDC Bearer (Cloud) / Internal |

---

## 4. Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `PORT` | No | `8080` | Port on which worker listens for push events |
| `HOST` | No | `0.0.0.0` | Bind interface address |
| `NODE_ENV` | No | `development` | Runtime mode (`development`, `production`, `test`) |
| `DATABASE_URL` | No | *(in-memory fallback)* | PostgreSQL connection URI |
| `DB_POOL_MAX` | No | `5` | Maximum database connections in worker pool |
| `PUBSUB_EMULATOR_HOST` | No | *(none)* | Pub/Sub local emulator host (e.g. `pubsub-emulator:8085`) |
| `PUBSUB_PROJECT_ID` | No | `local-project` | Google Cloud project ID |
| `PUBSUB_TOPIC_TASK_EVENTS`| No | `task-events` | Destination topic for task completion notifications |

---

## 5. Local Development

### Prerequisites
- Node.js >= 20.0.0
- npm >= 10.0.0

### Run Locally (Standalone)
```bash
cd services/worker
npm start
```

### Run Tests & Syntax Check
```bash
npm test
npm run lint
```

---

## 6. Container Execution

### Build Docker Image
```bash
docker build -t system-template-worker:latest services/worker/
```

### Run Container
```bash
docker run -p 8081:8080 \
  -e DATABASE_URL="postgres://postgres:postgres@localhost:5432/app_db" \
  system-template-worker:latest
```

### Healthcheck Probe
```bash
wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1
```
