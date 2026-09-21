# {{SYSTEM_NAME}} API Contracts (`contracts/api`)

Production-grade contract-first specification, mock definitions, and code-generation tooling for **{{SYSTEM_NAME}}**.

The single source of truth for the API surface is [`openapi.yaml`](./openapi.yaml), adhering strictly to the **OpenAPI 3.1.0** specification.

---

## Table of Contents

1. [Contract-First Philosophy](#contract-first-philosophy)
2. [Specification Overview](#specification-overview)
3. [Contract Validation and Linting](#contract-validation-and-linting)
4. [Mock Server Execution](#mock-server-execution)
5. [Code Generation Workflows](#code-generation-workflows)
   - [Go Backend (`oapi-codegen`)](#1-go-backend-oapi-codegen)
   - [TypeScript & Frontend (`Orval`)](#2-typescript--frontend-orval)
   - [Multi-Language SDKs (`OpenAPI Generator`)](#3-multi-language-sdks-openapi-generator)
   - [Autonomous AI Coding Agents](#4-autonomous-ai-coding-agents)
6. [Change Management & Versioning](#change-management--versioning)

---

## Contract-First Philosophy

In contract-first development, the API specification is finalized, reviewed, and validated **before any implementation code is written**. This guarantees:

- **Parallel Team Velocity**: Frontend, mobile, and backend engineers can build concurrently against mocked APIs without waiting for backend implementation.
- **Strict Boundary Enforcing**: Server-side request validation and client-side serialization share identical schemas, preventing data drifts.
- **AI Agent Determinism**: AI agents (Antigravity, Copilot, Claude) generate controllers, models, and test fixtures directly from the specification with zero hallucination.
- **Machine-Readable Documentation**: Always-synchronized documentation accessible via Swagger UI, Redoc, or API portals.

---

## Specification Overview

The API contract is located at [`contracts/api/openapi.yaml`](./openapi.yaml).

### Environments & Servers

| Environment | Base URL | Purpose |
| :--- | :--- | :--- |
| **Local Development** | `http://localhost:8080` | Local developer containers and mock servers |
| **Staging** | `https://staging-api.{{SYSTEM_DOMAIN:-example.com}}` | Automated CI/CD integration and QA tests |
| **Production** | `https://api.{{SYSTEM_DOMAIN:-example.com}}` | Live production traffic |

### Security Scheme

- **Scheme**: `BearerAuth` (HTTP Bearer)
- **Format**: JSON Web Token (JWT) issued by OIDC Identity Provider (e.g. Auth0, Keycloak, Firebase Auth).
- **Header**: `Authorization: Bearer <jwt_token>`
- **Exemptions**: Unauthenticated endpoints (e.g. `/healthz`) explicitly override security with `security: []`.

### Endpoints Summary

| Method | Path | Summary | Auth | Description |
| :--- | :--- | :--- | :---: | :--- |
| `GET` | `/healthz` | Health & Liveness Probe | Public | Returns service status, uptime, version, and backing database/cache health. |
| `GET` | `/api/v1/tasks` | List Tasks | Bearer | Paginated retrieval of tasks with `limit`, `offset`, `status`, and `priority` filters. |
| `POST` | `/api/v1/tasks` | Create Task | Bearer | Creates a new task with validation and idempotency key support. |
| `GET` | `/api/v1/tasks/{id}` | Retrieve Task | Bearer | Returns the complete status and execution payload of a task by UUID. |
| `PATCH` | `/api/v1/tasks/{id}` | Update Task | Bearer | Partial update of task status, priority tier, or execution parameters. |
| `DELETE` | `/api/v1/tasks/{id}` | Cancel/Soft-Delete Task | Bearer | Cancels an in-flight or scheduled task, or soft-deletes a completed task. |
| `POST` | `/api/v1/events/publish` | Ingest Domain Event | Bearer | Synchronous-to-asynchronous bridge ingestion to message broker (Kafka/PubSub). |

### Error Format (RFC 7807)

All non-2xx HTTP responses return `application/problem+json` conforming to **RFC 7807 (Problem Details for HTTP APIs)**:

```json
{
  "type": "https://errors.{{SYSTEM_DOMAIN:-example.com}}/validation-error",
  "title": "Bad Request",
  "status": 400,
  "detail": "Request payload failed validation on 2 fields",
  "instance": "/api/v1/tasks",
  "code": "ERR_VALIDATION_FAILED",
  "invalidParams": [
    {
      "name": "title",
      "reason": "Field 'title' must be between 1 and 255 characters",
      "code": "STRING_LENGTH_OUT_OF_RANGE"
    }
  ]
}
```

---

## Contract Validation and Linting

We enforce strict OpenAPI quality standards using [Spectral](https://stoplight.io/open-source/spectral).

### 1. Run Spectral Linting

Lint the specification locally against the standard OpenAPI ruleset:

```bash
# Run using npx (no global install required)
npx @stoplight/spectral-cli lint contracts/api/openapi.yaml

# Or if spectral is installed globally
spectral lint contracts/api/openapi.yaml
```

### 2. Spectral Ruleset Configuration (`.spectral.yaml`)

To enforce consistent company-wide rules, create `.spectral.yaml` at the repository root:

```yaml
extends: ["spectral:oas"]
rules:
  operation-description: error
  operation-tags: error
  no-eval: error
  no-script-tags-in-markdown: error
  openapi-tags: warn
```

### 3. CI/CD Automated Quality Gate

Add Spectral validation to your GitHub Actions workflow (`.github/workflows/contract-validation.yaml`):

```yaml
name: API Contract Validation
on:
  pull_request:
    paths:
      - "contracts/api/**"

jobs:
  lint-contract:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate OpenAPI 3.1 Specification
        run: |
          npx @stoplight/spectral-cli lint contracts/api/openapi.yaml --fail-severity=error
```

---

## Mock Server Execution

You can run local mock servers that instantly simulate the API for frontend development or integration tests.

### Option A: Mockoon CLI (Recommended)

Uses the pre-configured [`contracts/api/mock-server.json`](./mock-server.json) environment:

```bash
# Start mock server on port 8080
npx @mockoon/cli start --data contracts/api/mock-server.json --port 8080

# Verify health endpoint
curl -i http://localhost:8080/healthz

# Stop mock server
npx @mockoon/cli stop all
```

### Option B: Stoplight Prism (Dynamic OpenAPI Mocking)

Runs dynamically against [`contracts/api/openapi.yaml`](./openapi.yaml), validating requests and returning schema-compliant mock responses:

```bash
# Start Prism mock server on port 8080
npx @stoplight/prism-cli mock contracts/api/openapi.yaml -p 8080

# Test a request
curl -i http://localhost:8080/api/v1/tasks
```

### Option C: WireMock (Docker Container)

Run WireMock for integration test suites:

```bash
docker run -it --rm -p 8080:8080 \
  -v "$(pwd)/contracts/api/mock-server.json:/home/wiremock/mappings/mock-server.json" \
  wiremock/wiremock:latest
```

---

## Code Generation Workflows

Never hand-code HTTP models or request validators. Generate them directly from [`openapi.yaml`](./openapi.yaml).

### 1. Go Backend (`oapi-codegen`)

[oapi-codegen](https://github.com/oapi-codegen/oapi-codegen) generates idiomatic Go structs, chi/gin/echo router bindings, and request validators.

#### Step 1: Install `oapi-codegen`

```bash
go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest
```

#### Step 2: Configuration (`oapi-codegen.yaml`)

```yaml
package: api
generate:
  models: true
  chi-server: true
  client: true
  strict-server: true
output: internal/api/api.gen.go
```

#### Step 3: Run Generation

```bash
oapi-codegen -config oapi-codegen.yaml contracts/api/openapi.yaml
```

#### Step 4: Implement the Strict Server Interface

```go
package handlers

import (
    "context"
    "github.com/google/uuid"
    "yourproject/internal/api"
)

type TaskServiceHandler struct{}

func (h *TaskServiceHandler) GetHealth(ctx context.Context, request api.GetHealthRequestObject) (api.GetHealthResponseObject, error) {
    return api.GetHealth200JSONResponse{
        Status:        "UP",
        Version:       "1.0.0",
        UptimeSeconds: 120,
    }, nil
}
```

---

### 2. TypeScript & Frontend (`Orval`)

[Orval](https://orval.dev/) generates fully typed React Query (TanStack Query), SWR, or Axios clients with Zod validation schemas.

#### Step 1: Install Dependencies

```bash
npm install -D orval @tanstack/react-query axios
```

#### Step 2: Configuration (`orval.config.ts`)

```typescript
import { defineConfig } from "orval";

export default defineConfig({
  api: {
    input: "./contracts/api/openapi.yaml",
    output: {
      mode: "tags-split",
      target: "./src/api/endpoints",
      schemas: "./src/api/models",
      client: "react-query",
      mock: true,
      httpClient: "axios",
    },
  },
});
```

#### Step 3: Run Code Generation

```bash
npx orval
```

#### Step 4: Use in React Component

```tsx
import { useListTasks } from "@/api/endpoints/tasks";

export function TaskDashboard() {
  const { data, isLoading, error } = useListTasks({ limit: 10, offset: 0 });

  if (isLoading) return <div>Loading tasks...</div>;
  if (error) return <div>Error loading tasks: {error.message}</div>;

  return (
    <ul>
      {data?.items.map((task) => (
        <li key={task.id}>{task.title} - {task.status}</li>
      ))}
    </ul>
  );
}
```

---

### 3. Multi-Language SDKs (`OpenAPI Generator`)

Use the official [OpenAPI Generator](https://openapi-generator.tech/) for Python, Java, Rust, or C#:

```bash
# Python Client SDK
npx @openapitools/openapi-generator-cli generate \
  -i contracts/api/openapi.yaml \
  -g python \
  -o sdk/python \
  --additional-properties=packageName=system_api_client

# TypeScript Fetch Client SDK
npx @openapitools/openapi-generator-cli generate \
  -i contracts/api/openapi.yaml \
  -g typescript-fetch \
  -o sdk/typescript

# Java / Spring Server Stub
npx @openapitools/openapi-generator-cli generate \
  -i contracts/api/openapi.yaml \
  -g spring \
  -o backend/spring-stub \
  --additional-properties=interfaceOnly=true,useSpringBoot3=true
```

---

### 4. Autonomous AI Coding Agents

When delegating tasks to autonomous AI coding agents (e.g. Antigravity, GitHub Copilot Workspace, Claude Code):

1. **Provide Specification Path**: Instruct the agent:
   > "Implement the task management controller strictly conforming to `contracts/api/openapi.yaml`. Do not invent unmapped fields or custom error structures."
2. **Schema Invariants**: The agent uses the `components.schemas` and `components.responses` definitions to produce compile-time type bindings and RFC 7807 error dispatchers.
3. **Automated Verification**: The agent can verify its implementation by running contract tests against the mock server or validating payload serializers against the OpenAPI schema.

---

## Change Management & Versioning

To maintain backward compatibility:

1. **Non-Breaking Changes** (safe for minor releases):
   - Adding new optional fields to request bodies.
   - Adding new fields to response bodies.
   - Adding new endpoints.
   - Adding new optional query parameters.
2. **Breaking Changes** (require `/api/v2/` migration):
   - Renaming or removing existing fields.
   - Changing field types or enum values.
   - Adding mandatory request parameters or fields.
   - Altering authentication requirements on existing endpoints.
3. **Automated Breaking Change Detection**:
   Use `oasdiff` in CI/CD to block PRs introducing breaking changes:
   ```bash
   oasdiff breaking base.yaml contracts/api/openapi.yaml
   ```
