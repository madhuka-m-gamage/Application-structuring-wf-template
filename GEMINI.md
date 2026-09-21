# GEMINI.md: Antigravity & Gemini CLI Agent Guidance

> **Pass 4 Artifact**: Agent Steering, Scaffolding & Task Expansion (Zoom Level 4)  
> **Environment**: Google Antigravity IDE, Gemini CLI, and Gemini Autonomous Coding Agents  
> **Status**: Active & Authoritative  
> **Last Updated**: 2026-09-21

---

## 1. Architectural Grounding for Gemini Agents

As a Gemini or Antigravity AI coding agent working in this repository, you must anchor your cognitive model in the **5-Pass Progressive Plan Expansion Engine**:
* **Pass 1 (Discovery)**: `docs/00-discovery/` (Problem Statement, Personas, SLOs) & `docs/01-architecture/c4-context-model.md`
* **Pass 2 (Topology)**: `docs/01-architecture/system-rfc-template.md` & `docs/adr/`
* **Pass 3 (Contracts)**: `contracts/api/openapi.yaml`, `contracts/events/`, `contracts/database/schema.sql`
* **Pass 4 (Steering & Services)**: `AGENTS.md`, `.cursorrules`, `services/`, `docker-compose.yml`, `Makefile`
* **Pass 5 (IaC & Deployment)**: `infra/`, `.github/workflows/`, `monitoring/`

### Key Behavioral Rules:
1. **Contracts are SSOT**: Never assume an API schema or database structure. Always verify `contracts/` before generating code.
2. **Deterministic Outputs**: Output code that is strictly typed, formatted, and lint-clean.
3. **No Phantom Code**: Do not invent fake SDKs, unsupported GCP APIs, or unverified libraries. Stick to the active stack: TypeScript/Fastify, Go 1.22+, Python 3.11+, PostgreSQL 16, Cloud Run v2, and Cloud Pub/Sub.

---

## 2. Tool Use Guidelines & Efficiency

To minimize context churn and avoid execution failures, follow these tool use best practices:

### File Reading (`view_file`)
* **Targeted Lookups**: Read specific line ranges (`StartLine`, `EndLine`) rather than dumping 800+ lines.
* **Inspect Upstream Contracts First**: When tasked with an API or worker feature, read the relevant section in `contracts/api/openapi.yaml` or `contracts/events/` before viewing implementation files.

### File Editing (`replace_file_content` vs `write_to_file`)
* Use `replace_file_content` for targeted modifications to existing files. Provide precise contiguous matching text.
* Use `write_to_file` when creating new files or when performing a complete, fundamental rewrite of a small configuration file.
* Never strip or delete comments, docstrings, or machine-readable metadata (`<!-- @agent-meta: ... -->`).

### Command Execution (`run_command`)
* **Non-Interactive Execution**: Always pass non-interactive flags (e.g., `-y`, `--no-pager`, `CI=true`).
* **Verification Loop**: Always run `make verify` (or specific sub-targets like `make test`, `make lint`) after editing source code.
* **Inspect Command Return Codes**: Check return codes and stderr output carefully before claiming success.

---

## 3. Model Context Protocol (MCP) Integration

This repository is pre-configured with Model Context Protocol (MCP) integrations located in `.mcp/`. Gemini agents with MCP support should leverage these tools to interact directly with infrastructure, data, and repository systems:

### 3.1 Google Cloud Platform MCP (`gcp-mcp`)
Configured in `.mcp/gcp-mcp.json`. Use for Cloud Run and GCP diagnostics:
* `cloudrun_list_services`: List all deployed Cloud Run services across environments (`dev`, `staging`, `prod`).
* `cloudrun_get_service`: Inspect traffic splits, container images, environment variables, and CPU/memory allocations.
* `cloudrun_get_revisions`: View revision health, rollout status, and active traffic percentages.
* `cloudlogging_read_logs`: Query structured JSON logs using GCP log filters:
  ```
  resource.type="cloud_run_revision" AND severity>=ERROR
  ```
* `secretmanager_access_secret`: Inspect configuration variable schemas and verify secret presence without committing plaintext values.

### 3.2 PostgreSQL MCP (`postgres-mcp`)
Configured in `.mcp/postgres-mcp.json`. Use for schema inspection and database query tuning:
* `describe_table`: Inspect PostgreSQL 16 table structures, column types, nullability, and primary/foreign keys.
* `query`: Execute read-only SQL queries to verify seed data, migration state, or table contents during local testing.
* `explain_analyze`: Profile query plans to verify that indices on UUID foreign keys and timestamps are utilized efficiently.

### 3.3 GitHub MCP (`github-mcp`)
Configured in `.mcp/github-mcp.json`. Use for automated PR and repository workflows:
* `pull_request_read`: Read reviewer feedback, comments, and CI check statuses.
* `create_pull_request`: Open automated PRs with structured Conventional Commit titles and architectural summaries.
* `issue_read` / `issue_write`: Track task progress against development milestones.

---

## 4. Memory & Context Management Guidelines

Gemini models possess large context windows, but context quality directly dictates code accuracy:

### Context Hygiene
1. **Do not reload files you have already viewed** unless they were modified by an external tool or command.
2. **Summarize findings concisely**: When presenting findings or execution reports, avoid re-printing entire files. Present actionable summaries, file links, and key diffs.
3. **Grounding Priority Order**:
   ```
   1. contracts/           (OpenAPI, Pub/Sub JSON schemas, Database DDL)
   2. docs/adr/            (Accepted Architectural Decisions)
   3. docs/01-architecture/(System RFC & Container Models)
   4. services/            (Current Implementation Source)
   ```

### Anti-Hallucination Protocol
* If a request references a parameter, model, or route not found in `contracts/api/openapi.yaml`, **STOP** and flag the discrepancy. Do not invent speculative fields.
* If an event name is requested that is not present in `contracts/events/`, verify the CloudEvents schema before writing handler code.

---

## 5. Playbook Routing & Automated Workflows

When handling developer tasks, consult and execute the structured playbooks located in `.agents/playbooks/`:

| Developer Intent | Recommended Playbook | Command / File |
|---|---|---|
| **Design a new microservice** | 5-Pass Progressive Service Design | `.agents/playbooks/design-service.md` |
| **Add a new REST API endpoint** | Contract-First Endpoint Scaffolding | `.agents/playbooks/scaffold-endpoint.md` |
| **Pre-PR self-audit & verification** | Pre-PR Branch Verification | `.agents/playbooks/verify-branch.md` |

### Playbook Execution Standard
When executing a playbook:
1. Announce which playbook step is currently executing.
2. Complete each step in sequence without skipping verification gates.
3. Validate artifacts at each gate before proceeding to the next step.
