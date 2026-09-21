# Model Context Protocol (MCP) Integration Hub

<!-- @agent-meta: {"phase": "pass-4", "artifact": "mcp-server-hub", "system": "Task Management Microservices", "version": "1.0.0"} -->

## 1. Overview & Architecture

The **Model Context Protocol (MCP)** provides an open, standardized bridge between Large Language Model (LLM) agents and external enterprise systems, local runtime emulators, and cloud infrastructure.

In **Pass 4 (Agent Steering, Scaffolding & Task Expansion)**, MCP elevates AI coding agents (such as **Google Antigravity**, **Anthropic Claude Code**, **Cursor**, and **Windsurf**) from isolated text-generation engines into fully contextualized engineering partners. By integrating MCP servers, agents gain live, deterministic access to:
- **Cloud Infrastructure & Telemetry (GCP)**: Inspect deployed Cloud Run revisions, diagnose runtime crash exceptions via Cloud Logging, inspect Pub/Sub dead-letter queues, and verify secret configurations.
- **Relational Persistence (PostgreSQL)**: Inspect live database catalogs, verify active migration levels, check index structures, and execute safe, read-only diagnostic queries against local Docker or Cloud SQL databases.
- **Git & DevOps Lifecycle (GitHub)**: Automate pull request generation, review code changes, triage issues, and monitor CI/CD GitHub Actions execution traces.

```mermaid
flowchart TD
    subgraph AgentHarnesses["AI Coding Agent Environments"]
        AGY["Google Antigravity"]
        CC["Anthropic Claude Code"]
        CUR["Cursor IDE"]
        WS["Windsurf (Cascade)"]
    end

    subgraph MCPHub["Model Context Protocol (.mcp/) Hub"]
        GCP_MCP["GCP MCP Server<br/>(gcp-mcp.json)"]
        PG_MCP["PostgreSQL MCP Server<br/>(postgres-mcp.json)"]
        GH_MCP["GitHub MCP Server<br/>(github-mcp.json)"]
    end

    subgraph TargetRuntimes["Target Infrastructure & Data Plane"]
        subgraph GCP["Google Cloud Platform"]
            CR["Cloud Run Services & Revisions"]
            CL["Cloud Logging & Error Reporting"]
            PS["Cloud Pub/Sub Topics & Subscriptions"]
            SM["Secret Manager"]
        end

        subgraph DB["Relational Database"]
            LocalPG[("Local Docker PostgreSQL<br/>(taskdb:5432)")]
            CloudSQL[("Google Cloud SQL<br/>(PostgreSQL 16)")]
        end

        subgraph GitHub["GitHub Ecosystem"]
            PRs["Pull Requests & Code Reviews"]
            Issues["Issues & Milestones"]
            Actions["GitHub Actions Workflows"]
        end
    end

    AGY -->|JSON-RPC via stdio| MCPHub
    CC -->|JSON-RPC via stdio| MCPHub
    CUR -->|JSON-RPC via stdio| MCPHub
    WS -->|JSON-RPC via stdio| MCPHub

    GCP_MCP -->|GCP SDK / ADC Auth| GCP
    PG_MCP -->|Connection Pool / SSL| LocalPG
    PG_MCP -.->|Cloud SQL Proxy / IAM| CloudSQL
    GH_MCP -->|REST / GraphQL API| GitHub
```

---

## 2. Manifest of MCP Configuration Profiles

The `.mcp/` directory houses standardized MCP server profiles:

| Configuration File | Target Platform | Primary Tools Enabled | Authentication Method |
|---|---|---|---|
| [`gcp-mcp.json`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/.mcp/gcp-mcp.json) | Google Cloud Platform | Cloud Run revision inspection, Cloud Logging error fetching, Pub/Sub metrics, Secret Manager inspection | Application Default Credentials (ADC) / `GOOGLE_APPLICATION_CREDENTIALS` |
| [`postgres-mcp.json`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/.mcp/postgres-mcp.json) | PostgreSQL (Local / Cloud SQL) | `query`, `describe_table`, `list_tables`, `check_migrations` | Database credentials / Connection URI (`postgresql://...`) |
| [`github-mcp.json`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/.mcp/github-mcp.json) | GitHub Repository & Actions | PR creation/review, issue management, workflow run status & log triage | Fine-grained Personal Access Token (`GITHUB_PERSONAL_ACCESS_TOKEN`) |

---

## 3. Server Profiles & Tool Capabilities

### 3.1 Google Cloud Platform Server (`gcp-mcp.json`)

The GCP MCP server bridges agents directly into Google Cloud monitoring, serverless compute, and asynchronous event planes:

- **Cloud Run Inspection**:
  - `cloudrun_list_services`: Enumerate all running microservices in the target project and region (`task-api`, `task-worker`, `task-web`).
  - `cloudrun_get_service`: Inspect active traffic splits, ingress settings, and domain mappings.
  - `cloudrun_list_revisions`: View deployed revision history and timestamps.
  - `cloudrun_get_revision`: Inspect container image digest, allocated vCPUs/memory, concurrency settings, and environment variables.
- **Cloud Logging Diagnostics**:
  - `cloudlogging_fetch_errors`: Retrieve recent stack traces and high-severity (`ERROR`, `CRITICAL`) events across services within a sliding time window (e.g. last 30 minutes).
  - `cloudlogging_query_logs`: Execute arbitrary Google Cloud Logging queries to isolate intermittent failure modes or specific request trace IDs.
- **Secret Manager Payloads**:
  - `secretmanager_list_secrets`: Enumerate configured secrets without leaking secret data.
  - `secretmanager_get_payload`: Retrieve the decrypted payload of a specific secret version for environment validation or local debug emulation.
- **Pub/Sub Topic & Subscription Health**:
  - `pubsub_list_topics`: List messaging topics (`domain.events`, `task.queue`, `task.dlq`).
  - `pubsub_get_topic`: Inspect retention and KMS encryption settings.
  - `pubsub_list_subscriptions`: Inspect push endpoints and dead-letter queue policies.
  - `pubsub_get_subscription_metrics`: Retrieve unacknowledged message backlog count and oldest message age.

### 3.2 PostgreSQL Server (`postgres-mcp.json`)

The PostgreSQL MCP server connects agents to the relational database engine:

- **`query`**: Execute parameterized, read-only SQL queries with a strict 3-second statement timeout (e.g., verifying test records or checking index hit ratios).
- **`describe_table`**: Inspect table definition, column types, nullability, default values, primary keys, foreign key constraints, and indices.
- **`list_tables`**: Enumerate all relational tables, views, and materialized views in the `public` schema (`users`, `tasks`, `outbox_events`, `idempotency_keys`).
- **`check_migrations`**: Read schema migration metadata (`schema_migrations` or `flyway_schema_history`) to verify applied database version numbers and timestamps before generating schema changes.

### 3.3 GitHub Server (`github-mcp.json`)

The GitHub MCP server provides repository and CI/CD lifecycle automation:

- **Pull Request Management**:
  - `create_pull_request`: Open pull requests with Conventional Commit titles and structured markdown summaries.
  - `get_pull_request`: Inspect PR merge status, CI checks, and review comments.
  - `list_pull_requests`: Filter open or draft pull requests.
  - `create_pull_request_review`: Submit automated code reviews (`APPROVE`, `REQUEST_CHANGES`, `COMMENT`).
- **Issue Triage**:
  - `create_issue`: Open structured bug reports or task tracking cards.
  - `get_issue` / `list_issues`: Query active backlog items and labels.
  - `update_issue`: Mark issues as closed upon successful verification.
- **CI/CD Actions Telemetry**:
  - `list_workflow_runs`: List recent GitHub Actions runs for the current branch.
  - `get_workflow_run`: Inspect status (`queued`, `in_progress`, `completed`) and conclusion (`success`, `failure`).
  - `get_workflow_run_logs`: Fetch failed step logs directly into the agent context for instantaneous debugging.

---

## 4. Setup & Client Configuration Guide

### 4.1 Unified Multi-Server Configuration Snippet

For clients that accept a single consolidated `mcpServers` object, combine all three servers into your client configuration:

```json
{
  "mcpServers": {
    "gcp": {
      "command": "npx",
      "args": ["-y", "@google-cloud/mcp-server-gcp"],
      "env": {
        "GCP_PROJECT_ID": "my-gcp-project-id",
        "GCP_REGION": "us-central1",
        "GOOGLE_APPLICATION_CREDENTIALS": "/home/developer/.config/gcloud/application_default_credentials.json"
      }
    },
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://postgres:postgres@localhost:5432/taskdb?sslmode=disable"
      ],
      "env": {
        "POSTGRES_HOST": "localhost",
        "POSTGRES_PORT": "5432",
        "POSTGRES_USER": "postgres",
        "POSTGRES_PASSWORD": "postgres",
        "POSTGRES_DB": "taskdb",
        "POSTGRES_SSLMODE": "disable"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_yourPersonalAccessTokenHere",
        "GITHUB_OWNER": "your-org-or-username",
        "GITHUB_REPO": "Application-structuring-wf-template"
      }
    }
  }
}
```

---

### 4.2 Google Antigravity Configuration

Google Antigravity automatically discovers MCP servers defined in the user config directory or workspace settings.

1. **Global Configuration**:
   Add MCP server definitions to `~/.gemini/antigravity/mcp/` or your global config:
   ```bash
   mkdir -p ~/.gemini/antigravity/mcp
   ```
2. **Workspace Tool Manifest**:
   In Antigravity, tools are registered and available as lazy or eager tools. You can verify available MCP servers in Antigravity by checking the system tool declarations or using `manage_task` and `call_mcp_tool`.

---

### 4.3 Anthropic Claude Code Configuration

Claude Code natively supports adding and managing MCP servers via the CLI:

```bash
# 1. Add PostgreSQL Server (pointing to local Docker container)
claude mcp add postgres npx -y @modelcontextprotocol/server-postgres "postgresql://postgres:postgres@localhost:5432/taskdb?sslmode=disable"

# 2. Add GitHub Server
claude mcp add github -e GITHUB_PERSONAL_ACCESS_TOKEN="ghp_yourToken" npx -y @modelcontextprotocol/server-github

# 3. Add Google Cloud Platform Server
claude mcp add gcp -e GCP_PROJECT_ID="my-project" -e GCP_REGION="us-central1" npx -y @google-cloud/mcp-server-gcp

# 4. Verify registered servers
claude mcp list
```

Alternatively, configure `~/.claude.json` or `.claude/mcp.json` using the consolidated JSON format above.

---

### 4.4 Cursor IDE Configuration

1. Open Cursor Settings (`Ctrl+,` or `Cmd+,`) and navigate to **Features** > **MCP**.
2. Alternatively, create or edit `.cursor/mcp.json` in your workspace root:
   ```json
   {
     "mcpServers": {
       "postgres": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://postgres:postgres@localhost:5432/taskdb?sslmode=disable"]
       },
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "${env:GITHUB_PERSONAL_ACCESS_TOKEN}"
         }
       }
     }
   }
   ```
3. Click **Reload MCP Servers** in the Cursor UI. A green indicator will verify connection health.

---

### 4.5 Windsurf (Codeium Cascade) Configuration

Windsurf stores its MCP configuration in the user's Codeium configuration directory:

1. Locate `~/.codeium/windsurf/mcp_config.json`.
2. Paste the `mcpServers` block from [Section 4.1](#41-unified-multi-server-configuration-snippet).
3. Restart Cascade or run **Cascade: Refresh MCP Servers** from the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).

---

## 5. Security Best Practices & Guardrails

Connecting autonomous AI agents to live databases and cloud infrastructure requires strict, defense-in-depth security policies:

### 5.1 Read-Only vs. Read-Write Scoping

1. **PostgreSQL Safeguards**:
   - **Never connect agents with `SUPERUSER` or `postgres` admin roles in production environments.**
   - In production or shared staging databases, provision a dedicated, unprivileged read-only role:
     ```sql
     -- Create restricted agent role
     CREATE ROLE agent_readonly WITH LOGIN PASSWORD 'strong_password_here';
     GRANT CONNECT ON DATABASE taskdb TO agent_readonly;
     GRANT USAGE ON SCHEMA public TO agent_readonly;
     GRANT SELECT ON ALL TABLES IN SCHEMA public TO agent_readonly;
     ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO agent_readonly;
     
     -- Enforce statement execution ceiling
     ALTER ROLE agent_readonly SET statement_timeout = '3000ms';
     ALTER ROLE agent_readonly SET default_transaction_read_only = on;
     ```
   - All destructive operations (`DROP`, `TRUNCATE`, `ALTER`, `DELETE`, `UPDATE`) will be rejected at the PostgreSQL transaction level.

2. **Google Cloud Platform IAM Safeguards**:
   - Grant agents read-only viewer roles adhering to the Principle of Least Privilege:
     - `roles/run.viewer` (inspect Cloud Run configuration, cannot deploy or delete revisions)
     - `roles/logging.viewer` (read error traces, cannot delete log sinks)
     - `roles/pubsub.viewer` (inspect topics and metrics, cannot purge queues or delete subscriptions)
     - `roles/secretmanager.secretAccessor` (limited strictly to required runtime secrets)
   - **Strictly Prohibited**: `roles/owner`, `roles/editor`, `roles/iam.serviceAccountAdmin`.

3. **GitHub Token Scoping**:
   - Use **Fine-grained Personal Access Tokens (PATs)** scoped exclusively to this repository.
   - Restrict permissions to:
     - `Pull requests`: Read and Write (for creating PRs and posting reviews)
     - `Issues`: Read and Write (for updating task status)
     - `Actions`: Read-only (for monitoring build and test status)
   - Do **NOT** grant `Administration: Read/Write` or `Workflows: Write`.

### 5.2 Zero-Secrets Policy & Credential Isolation

- **Never commit credentials to git**: Configuration files in `.mcp/` use environment variable interpolation (e.g. `${GCP_PROJECT_ID}`, `${GITHUB_PERSONAL_ACCESS_TOKEN}`).
- Store sensitive values in an untracked `.env.mcp` file or export them directly in your shell:
  ```bash
  # Example .env.mcp (ensure this file is in .gitignore!)
  export GCP_PROJECT_ID="task-mgmt-production"
  export GCP_REGION="us-central1"
  export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
  export POSTGRES_PASSWORD="secure_local_password"
  ```
- **Application Default Credentials (ADC)**: For Google Cloud, prefer ADC over static JSON key files:
  ```bash
  gcloud auth application-default login
  ```
  This creates temporary, self-refreshing OAuth2 tokens under `~/.config/gcloud/application_default_credentials.json`, eliminating long-lived service account keys on developer machines.

---

## 6. Local Emulator & Docker Integration

During development and CI verification, agents should target local emulators rather than live cloud environments.

### 6.1 Connecting `postgres-mcp` to Local Docker PostgreSQL

The project includes containerized PostgreSQL (detailed in `docker-compose.yml`):

1. **Launch the database container**:
   ```bash
   docker compose up -d postgres
   ```
2. **Apply schema contracts**:
   ```bash
   docker compose exec -T postgres psql -U postgres -d taskdb < contracts/database/schema.sql
   ```
3. **Configure `postgres-mcp`**:
   The default parameters in `postgres-mcp.json` automatically target `localhost:5432` with user `postgres` and database `taskdb`:
   ```bash
   # Test connection directly with npx
   npx -y @modelcontextprotocol/server-postgres "postgresql://postgres:postgres@localhost:5432/taskdb?sslmode=disable"
   ```

### 6.2 Connecting to Local Cloud Pub/Sub Emulator

To test Pub/Sub topics locally without GCP spend:

1. **Launch the Google Cloud Pub/Sub emulator**:
   ```bash
   docker compose up -d pubsub-emulator
   ```
2. **Export emulator host**:
   ```bash
   export PUBSUB_EMULATOR_HOST="localhost:8085"
   ```
3. Local SDK clients and MCP bridge tools will automatically redirect traffic from `pubsub.googleapis.com` to the local mock instance.

### 6.3 Testing MCP Servers with MCP Inspector

You can interactively test and debug any MCP server using the official Model Context Protocol Inspector UI:

```bash
# Test PostgreSQL MCP server interactively:
npx @modelcontextprotocol/inspector npx -y @modelcontextprotocol/server-postgres "postgresql://postgres:postgres@localhost:5432/taskdb?sslmode=disable"

# Test GitHub MCP server:
GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxx" npx @modelcontextprotocol/inspector npx -y @modelcontextprotocol/server-github
```

The inspector launches a local web UI (typically at `http://localhost:5173`) where you can inspect available tool schemas, issue requests, and view raw JSON-RPC payloads.

---

## 7. Common Agent Playbooks & Scenarios

### Scenario A: Triaging Production 500 Errors
1. Agent calls `cloudlogging_fetch_errors(service_name="task-api", time_window_minutes=15)`.
2. Identifies a `NullPointerException` or unhandled database connection timeout.
3. Agent calls `cloudrun_get_revision(service_name="task-api", revision_name="task-api-00012-abc")` to inspect environment variables and resource allocations.
4. Agent isolates the bug, fixes the application code, and writes a regression unit test.

### Scenario B: Verifying Schema Changes Before Migration
1. Before proposing a new migration script, agent calls `check_migrations()`.
2. Verifies the latest applied migration version in the target database.
3. Agent calls `describe_table(table_name="tasks")` to confirm current column names, data types, and index constraints.
4. Agent generates an expand-and-contract safe SQL migration script according to [`contracts/database/README.md`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/contracts/database/README.md).

### Scenario C: Autonomous Feature Verification & Pull Request
1. Agent implements a new feature on branch `feat/task-deadline`.
2. Agent runs local verification (`make verify`).
3. Agent commits changes using Conventional Commits.
4. Agent calls `create_pull_request(title="feat: implement task deadline expiration worker", head="feat/task-deadline", base="main", body="...")`.
5. Agent calls `list_workflow_runs(branch="feat/task-deadline")` to monitor CI status until green.

---

## 8. Troubleshooting & Diagnostics

| Symptom | Probable Cause | Remediation |
|---|---|---|
| `connection refused at localhost:5432` | Local PostgreSQL Docker container is stopped or still booting. | Run `docker compose ps` and `docker compose logs postgres`. Ensure port 5432 is mapped to host. |
| `HTTP 401: Bad credentials` in GitHub MCP | Missing, invalid, or expired `GITHUB_PERSONAL_ACCESS_TOKEN`. | Regenerate a fine-grained token at GitHub > Settings > Developer Settings with `repo` and `actions` permissions. |
| `Could not find default credentials` in GCP MCP | Missing Google Cloud credentials. | Run `gcloud auth application-default login` or set `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`. |
| `canceling statement due to statement timeout` | Query exceeded the 3000ms safety limit. | Optimize query with an index or narrow the filter; avoid full table scans (`Seq Scan`) on unindexed columns. |
| `Spawn npx ENOENT` | Node.js or `npx` not found on system PATH. | Ensure Node.js (v18+) and npm are installed and available on system PATH (`which npx`). |
