# System Design-to-Deployment Workflow Template Implementation Plan (5 Rounds)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Within each round, use superpowers:dispatching-parallel-agents to execute independent tasks in parallel. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, agent-native SDLC workflow template in this repository that guides development teams and autonomous AI agents from system architecture design through contracts, scaffolding, and Terraform IaC to Google Cloud Platform deployment and observability across 5 structured rounds.

**Architecture:** A multi-tier microservices architecture (Frontend Web, API Backend, Background Worker, PostgreSQL, Cloud Pub/Sub) running on GCP Cloud Run serverless containers, governed by OpenAPI and Pub/Sub event contracts, managed via modular Terraform, and automated with GitHub Actions utilizing Workload Identity Federation (WIF) and MCP server tooling.

**Tech Stack:** Markdown/Mermaid, OpenAPI 3.1, JSON Schema, PostgreSQL DDL, Docker/Docker Compose, Terraform (GCP Provider), GitHub Actions, Workload Identity Federation, GCP Cloud Run v2, Cloud Pub/Sub, Cloud SQL, Cloud Monitoring/Logging, Model Context Protocol (MCP).

**Spec:** [`docs/superpowers/specs/2026-09-21-system-design-to-deployment-workflow-template-design.md`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/docs/superpowers/specs/2026-09-21-system-design-to-deployment-workflow-template-design.md)

## Global Constraints
- Every template document must include YAML frontmatter and clear placeholder annotations (`{{VARIABLE_NAME}}`) with complete accompanying explanation.
- No dummy/unusable code: all schema files, Dockerfiles, Terraform configs, and GitHub workflows must be syntactically valid and pass linter/validator checks.
- Zero raw secrets: all GCP authentication must use Workload Identity Federation (WIF) or Secret Manager; no plaintext service account keys.
- Docker containers must adhere to non-root least-privilege standards and multi-stage builds.
- All tasks within a Round are designed for parallel subagent dispatch via `superpowers:dispatching-parallel-agents`.

## Review Focus
1. Contract-to-Implementation drift: Ensure OpenAPI endpoints and Pub/Sub topic names match exactly across contracts, Terraform configs, and CI/CD pipelines.
2. Keyless WIF security: Ensure GitHub Actions workflows use OIDC tokens and omit static GCP credentials.
3. Private networking isolation: Ensure Cloud SQL and Cloud Run talk via Serverless VPC Connector without public IP database exposure.
4. Agent usability: Ensure `AGENTS.md` and `.cursorrules` have concise, actionable guardrails that prevent AI hallucination.
5. Local vs Cloud parity: Ensure `docker-compose.yml` provides a functional local facsimile of the GCP cloud runtime.

---

## Round 1: Foundation & Architecture Blueprint

### Task 1.1: System Intent & Requirements Discovery Framework
**Files:**
- Create: `docs/00-discovery/problem-statement-template.md`
- Create: `docs/00-discovery/success-metrics-template.md`
- Create: `docs/00-discovery/README.md`

**Interfaces:**
- Consumes: Business requirements and user goals.
- Produces: Machine-readable requirements for C4 modeling and RFC design.

- [ ] **Step 1: Write requirements discovery templates**
  - Author `docs/00-discovery/problem-statement-template.md` covering background, personas, functional requirements, and non-functional requirements (SLAs, throughput, latency).
  - Author `docs/00-discovery/success-metrics-template.md` defining quantifiable KPIs, SLO/SLI error budgets, and exit criteria.
  - Author `docs/00-discovery/README.md` explaining how engineers and AI agents use this discovery phase.
- [ ] **Step 2: Validate document structure and links**
  - Verify formatting and markdown integrity.
- [ ] **Step 3: Commit**
  ```bash
  git add docs/00-discovery/
  git commit -m "docs: add Round 1 discovery and problem statement templates"
  ```

### Task 1.2: System Architecture RFC & C4 Mermaid Modeling
**Files:**
- Create: `docs/01-architecture/system-rfc-template.md`
- Create: `docs/01-architecture/c4-architecture-template.md`
- Create: `docs/01-architecture/README.md`

**Interfaces:**
- Consumes: Discovery templates from Task 1.1.
- Produces: C4 Level 1 Context and C4 Level 2 Container diagrams and communication flow specifications.

- [ ] **Step 1: Write System RFC template**
  - Author `docs/01-architecture/system-rfc-template.md` with sections: Overview, System Goals, Component Topology, Data Ingestion/Egress, Synchronous vs. Asynchronous patterns, Security, and Scalability.
- [ ] **Step 2: Write C4 Architecture template with Mermaid**
  - Author `docs/01-architecture/c4-architecture-template.md` containing interactive Mermaid C4 diagrams illustrating Frontend Web, Backend API, Pub/Sub, Worker, and Cloud SQL.
- [ ] **Step 3: Commit**
  ```bash
  git add docs/01-architecture/
  git commit -m "docs: add Round 1 system RFC and C4 architecture templates"
  ```

### Task 1.3: Architecture Decision Records (ADR) Framework
**Files:**
- Create: `docs/adr/README.md`
- Create: `docs/adr/template.md`
- Create: `docs/adr/0001-record-architecture-decisions.md`
- Create: `docs/adr/0002-cloud-run-serverless-microservices.md`

**Interfaces:**
- Consumes: Architecture trade-offs from RFC.
- Produces: Versioned ADR log recording technological decisions and trade-offs.

- [ ] **Step 1: Write ADR template and standard records**
  - Author `docs/adr/template.md` based on the standard Nygard format (Status, Context, Decision, Consequences).
  - Create `docs/adr/0001-record-architecture-decisions.md` establishing the ADR pattern.
  - Create `docs/adr/0002-cloud-run-serverless-microservices.md` codifying Cloud Run + Pub/Sub selection over GKE.
- [ ] **Step 2: Verify and commit**
  ```bash
  git add docs/adr/
  git commit -m "docs: add Round 1 ADR framework and initial architectural records"
  ```

---

## Round 2: Contracts, Interfaces & Schema Specifications

### Task 2.1: OpenAPI 3.1 REST API Specification & Mock Contracts
**Files:**
- Create: `contracts/api/openapi.yaml`
- Create: `contracts/api/mock-server.json`
- Create: `contracts/api/README.md`

**Interfaces:**
- Consumes: C4 API component boundaries from Round 1.
- Produces: Strict schema-anchored endpoints, request bodies, RFC 7807 problem details, and mock responses.

- [ ] **Step 1: Author OpenAPI 3.1 specification**
  - Define `/healthz`, `/api/v1/tasks` (CRUD), and `/api/v1/events` endpoints.
  - Include schemas with validation rules, examples, and standard HTTP error models.
- [ ] **Step 2: Provide mock server configuration and instructions**
  - Add `contracts/api/mock-server.json` for Prism or WireMock mocking.
- [ ] **Step 3: Validate and commit**
  ```bash
  git add contracts/api/
  git commit -m "feat: add Round 2 OpenAPI 3.1 contracts and mock specifications"
  ```

### Task 2.2: Cloud Pub/Sub Event Schemas & Message Definitions
**Files:**
- Create: `contracts/events/event-envelope.json`
- Create: `contracts/events/task-created.v1.json`
- Create: `contracts/events/README.md`

**Interfaces:**
- Consumes: Asynchronous worker requirements.
- Produces: CloudEvents-compliant JSON schemas for event publishing and consumption.

- [ ] **Step 1: Author CloudEvents JSON schemas**
  - Create `event-envelope.json` with CloudEvents 1.0 standard fields (`id`, `source`, `type`, `specversion`, `time`, `data`).
  - Create `task-created.v1.json` defining the payload for worker asynchronous execution.
- [ ] **Step 2: Commit**
  ```bash
  git add contracts/events/
  git commit -m "feat: add Round 2 CloudEvents-compliant Pub/Sub schemas"
  ```

### Task 2.3: Database DDL Schema & Entity Relationship Model
**Files:**
- Create: `contracts/database/schema.sql`
- Create: `contracts/database/erd.md`
- Create: `contracts/database/README.md`

**Interfaces:**
- Consumes: Domain entities from API and event contracts.
- Produces: PostgreSQL DDL with tables, relations, indexes, triggers, and visual Mermaid ERD.

- [ ] **Step 1: Author PostgreSQL DDL**
  - Define `users`, `tasks`, and `outbox_events` tables with UUID primary keys, timestamps, indexes, and constraints.
- [ ] **Step 2: Author Mermaid ERD**
  - Create `contracts/database/erd.md` visualizing entity cardinality and foreign keys.
- [ ] **Step 3: Commit**
  ```bash
  git add contracts/database/
  git commit -m "feat: add Round 2 database DDL schema and visual ERD"
  ```

---

## Round 3: Agent Steering, MCP Tooling & Development Scaffolding

### Task 3.1: Agent Context, Rules & Prompt Playbooks
**Files:**
- Create: `AGENTS.md`
- Create: `.cursorrules`
- Create: `GEMINI.md`
- Create: `.agents/playbooks/design-service.md`
- Create: `.agents/playbooks/scaffold-endpoint.md`
- Create: `.agents/playbooks/verify-branch.md`

**Interfaces:**
- Consumes: Project architecture and conventions.
- Produces: Explicit instructions, boundaries, and executable prompts for AI agents.

- [ ] **Step 1: Author AGENTS.md, .cursorrules, and GEMINI.md**
  - Document repository topology, contract-first rules, coding conventions, testing rules, and forbidden antipatterns.
- [ ] **Step 2: Create agent slash command playbooks**
  - Author reusable prompt workflows in `.agents/playbooks/`.
- [ ] **Step 3: Commit**
  ```bash
  git add AGENTS.md .cursorrules GEMINI.md .agents/
  git commit -m "feat: add Round 3 agent steering rules and prompt playbooks"
  ```

### Task 3.2: Model Context Protocol (MCP) Integration Hub
**Files:**
- Create: `.mcp/gcp-mcp.json`
- Create: `.mcp/postgres-mcp.json`
- Create: `.mcp/github-mcp.json`
- Create: `.mcp/README.md`

**Interfaces:**
- Consumes: MCP tool definitions.
- Produces: Ready-to-use MCP server configurations for connecting coding agents to GCP, Postgres, and GitHub.

- [ ] **Step 1: Write MCP server configuration profiles**
  - Create configuration files for GCP MCP (Cloud Run, Cloud Logging, Secret Manager), Postgres MCP, and GitHub MCP.
  - Document setup steps and permission requirements in `.mcp/README.md`.
- [ ] **Step 2: Commit**
  ```bash
  git add .mcp/
  git commit -m "feat: add Round 3 MCP server configuration hub and guides"
  ```

### Task 3.3: Containerized Scaffolding & Local Feedback Loop
**Files:**
- Create: `docker-compose.yml`
- Create: `Makefile`
- Create: `services/web/Dockerfile` & `services/web/README.md`
- Create: `services/api/Dockerfile` & `services/api/README.md`
- Create: `services/worker/Dockerfile` & `services/worker/README.md`

**Interfaces:**
- Consumes: Microservices topology.
- Produces: Local orchestration environment and single-command verification (`make verify`).

- [ ] **Step 1: Create multi-stage non-root Dockerfiles**
  - Build hardened Dockerfiles for web, api, and worker services.
- [ ] **Step 2: Create docker-compose.yml and Makefile**
  - Orchestrate web, api, worker, PostgreSQL, and Pub/Sub emulator in `docker-compose.yml`.
  - Author `Makefile` with targets: `help`, `verify`, `lint`, `test`, `docker-up`, `docker-down`, `clean`.
- [ ] **Step 3: Test and commit**
  - Verify `docker-compose.yml` syntax via `docker compose config` if available.
  ```bash
  git add docker-compose.yml Makefile services/
  git commit -m "feat: add Round 3 multi-tier container scaffolding and Makefile harness"
  ```

---

## Round 4: Infrastructure as Code (GCP Terraform Modules & Environments)

### Task 4.1: Networking, IAM & Workload Identity Federation (WIF) Modules
**Files:**
- Create: `infra/modules/vpc/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/iam_wif/{main.tf, variables.tf, outputs.tf}`

**Interfaces:**
- Consumes: GCP Project ID and region.
- Produces: Private VPC, Serverless VPC Access connector, and keyless GitHub Actions WIF pool.

- [ ] **Step 1: Author VPC and Serverless Access module**
- [ ] **Step 2: Author Workload Identity Federation (WIF) module**
- [ ] **Step 3: Commit**
  ```bash
  git add infra/modules/vpc/ infra/modules/iam_wif/
  git commit -m "feat: add Round 4 Terraform VPC and WIF IAM modules"
  ```

### Task 4.2: Compute & Artifact Registry Modules
**Files:**
- Create: `infra/modules/artifact_registry/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/cloud_run/{main.tf, variables.tf, outputs.tf}`

**Interfaces:**
- Consumes: VPC connector and image repositories.
- Produces: Artifact Registry Docker repository and Cloud Run v2 services for Web, API, and Worker.

- [ ] **Step 1: Author Artifact Registry module**
- [ ] **Step 2: Author Cloud Run v2 module with auto-scaling and health probes**
- [ ] **Step 3: Commit**
  ```bash
  git add infra/modules/artifact_registry/ infra/modules/cloud_run/
  git commit -m "feat: add Round 4 Terraform Artifact Registry and Cloud Run modules"
  ```

### Task 4.3: Data & Messaging Modules (Cloud SQL & Pub/Sub)
**Files:**
- Create: `infra/modules/cloud_sql/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/pubsub/{main.tf, variables.tf, outputs.tf}`

**Interfaces:**
- Consumes: Private VPC network.
- Produces: Private Cloud SQL PostgreSQL instance and Pub/Sub topics with Dead Letter Queue (DLQ).

- [ ] **Step 1: Author Cloud SQL PostgreSQL module with private IP**
- [ ] **Step 2: Author Cloud Pub/Sub module with DLQ subscription**
- [ ] **Step 3: Commit**
  ```bash
  git add infra/modules/cloud_sql/ infra/modules/pubsub/
  git commit -m "feat: add Round 4 Terraform Cloud SQL and Pub/Sub modules"
  ```

### Task 4.4: Environment Roots (Dev, Staging, Prod)
**Files:**
- Create: `infra/environments/dev/{main.tf, variables.tf, outputs.tf, terraform.tfvars.example}`
- Create: `infra/environments/staging/{main.tf, variables.tf, outputs.tf, terraform.tfvars.example}`
- Create: `infra/environments/prod/{main.tf, variables.tf, outputs.tf, terraform.tfvars.example}`
- Create: `infra/README.md`

**Interfaces:**
- Consumes: All Terraform modules from Tasks 4.1 - 4.3.
- Produces: Deployable environment roots with environment-specific scaling and budget guardrails.

- [ ] **Step 1: Author environment roots**
- [ ] **Step 2: Validate Terraform configuration formatting**
- [ ] **Step 3: Commit**
  ```bash
  git add infra/environments/ infra/README.md
  git commit -m "feat: add Round 4 Terraform multi-environment roots (dev, staging, prod)"
  ```

---

## Round 5: Automated CI/CD, Progressive Rollout & Observability

### Task 5.1: GitHub Actions CI Pipeline with Security Scanning
**Files:**
- Create: `.github/workflows/ci.yaml`

**Interfaces:**
- Consumes: Code changes across PRs.
- Produces: Automated linting, test validation, Docker build, and Trivy CVE vulnerability reports.

- [ ] **Step 1: Author .github/workflows/ci.yaml**
  - Implement lint, test, contract validation, and container build checks.
- [ ] **Step 2: Commit**
  ```bash
  git add .github/workflows/ci.yaml
  git commit -m "ci: add Round 5 GitHub Actions CI pipeline with Trivy scanning"
  ```

### Task 5.2: GitHub Actions Progressive CD Pipelines (Staging & Prod)
**Files:**
- Create: `.github/workflows/deploy-staging.yaml`
- Create: `.github/workflows/deploy-prod.yaml`

**Interfaces:**
- Consumes: Approved merges to main/release tags.
- Produces: WIF-authenticated container pushes to Artifact Registry and Cloud Run revision deployments with traffic splitting.

- [ ] **Step 1: Author deploy-staging.yaml**
  - Automated deployment to `dev`/`staging` upon merge to `main`.
- [ ] **Step 2: Author deploy-prod.yaml**
  - Gated production rollout with canary traffic allocation (10% -> 100%) triggered by semantic tags.
- [ ] **Step 3: Commit**
  ```bash
  git add .github/workflows/deploy-*.yaml
  git commit -m "ci: add Round 5 progressive CD pipelines with WIF and traffic splitting"
  ```

### Task 5.3: Production Observability, Alert Policies & Incident Runbooks
**Files:**
- Create: `monitoring/alert-policies.yaml`
- Create: `monitoring/logging-config.md`
- Create: `docs/03-operations/incident-runbook.md`
- Create: `docs/03-operations/slo-sli-definitions.md`
- Create: `README.md` (Top-level template documentation)

**Interfaces:**
- Consumes: GCP telemetry standards.
- Produces: Alerting rules, SLO metrics, operational incident response procedures, and master repository documentation.

- [ ] **Step 1: Author alert policies and logging guide**
  - Define metric alerts for HTTP 5xx errors, latency spikes, and container restart loops.
- [ ] **Step 2: Author incident runbook and SLO definitions**
  - Document rollback procedures, database restore steps, and SLO breach escalation.
- [ ] **Step 3: Author master README.md**
  - Provide onboarding guide for developers and AI agents navigating the 5-round template.
- [ ] **Step 4: Commit**
  ```bash
  git add monitoring/ docs/03-operations/ README.md
  git commit -m "feat: add Round 5 observability, incident runbooks, and master README"
  ```
