# Backend API Service (`services/api/`)

The **Backend API Service** is the central ingress gateway and business logic orchestration container in the **System Design-to-Deployment Template**. It is designed to run as a stateless service on **Google Cloud Run (v2)**, interacting with **PostgreSQL 16** via connection pooling and emitting asynchronous domain events to **Google Cloud Pub/Sub** using the Transactional Outbox Pattern.

---

## 1. Architectural Role & Standards

- **Runtime**: Node.js 20 LTS (Lightweight, Alpine multi-stage container)
- **Execution Context**: Unprivileged non-root user `appuser` (UID 10001)
- **API Contract**: Defined strictly by [`contracts/api/openapi.yaml`](../../contracts/api/openapi.yaml) (OpenAPI 3.1.0)
- **Persistence**: PostgreSQL 16 schema defined in [`contracts/database/schema.sql`](../../contracts/database/schema.sql)
- **Event Dispatch**: CloudEvents v1.0 standard defined in [`contracts/events/`](../../contracts/events/)
- **Reliability**: Transactional Outbox Pattern (`outbox_events` table) guarantees zero dual-write anomalies

---

## 2. API Endpoints

| Method | Path | Description | Security | Contract Ref |
|---|---|---|---|---|
| `GET` | `/healthz` | Liveness and dependency readiness probe | Public | `#/paths/~1healthz` |
| `GET` | `/api/v1/tasks` | List tasks with pagination & status filtering | Public / Bearer | `#/paths/~1api~1v1~1tasks` |
| `POST` | `/api/v1/tasks` | Submit new task & stage outbox event | Bearer | `#/paths/~1api~1v1~1tasks` |
| `GET` | `/api/v1/tasks/:id` | Retrieve task details and execution result | Bearer | `#/paths/~1api~1v1~1tasks~1{id}` |
| `DELETE`| `/api/v1/tasks/:id` | Cancel or delete a task | Bearer | `#/paths/~1api~1v1~1tasks~1{id}` |

---

## 3. Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `PORT` | No | `8080` | Port on which the HTTP server listens |
| `HOST` | No | `0.0.0.0` | Bind interface address |
| `NODE_ENV` | No | `development` | Runtime environment (`development`, `production`, `test`) |
| `DATABASE_URL` | No | *(in-memory fallback)* | PostgreSQL connection URI (`postgres://user:pass@host:5432/dbname`) |
| `DB_POOL_MAX` | No | `10` | Maximum connections in PostgreSQL connection pool |
| `PUBSUB_EMULATOR_HOST` | No | *(none)* | Host and port for Cloud Pub/Sub local emulator (e.g. `pubsub-emulator:8085`) |
| `PUBSUB_PROJECT_ID` | No | `local-project` | Google Cloud project ID for Pub/Sub topics |
| `PUBSUB_TOPIC_TASKS` | No | `tasks` | Topic name for task creation domain events |

---

## 4. Local Development

### Prerequisites
- Node.js >= 20.0.0
- npm >= 10.0.0

### Run Locally (Standalone / Mock Mode)
```bash
cd services/api
npm start
```
The server will boot with resilient in-memory stores and mock adapters if PostgreSQL or Pub/Sub emulator are not present.

### Run Tests & Syntax Check
```bash
npm test
npm run lint
```

---

## 5. Container Execution

### Build Docker Image
```bash
docker build -t system-template-api:latest services/api/
```

### Run Container
```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="postgres://postgres:postgres@localhost:5432/app_db" \
  system-template-api:latest
```

### Healthcheck Probe
The container includes a built-in Docker healthcheck:
```bash
wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/healthz || exit 1
```
