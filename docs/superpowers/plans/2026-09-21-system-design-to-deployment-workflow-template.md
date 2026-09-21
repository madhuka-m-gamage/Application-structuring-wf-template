# System Design-to-Deployment Workflow Template Implementation Plan (5-Pass Progressive Expansion)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Across each expansion pass, use superpowers:dispatching-parallel-agents to execute independent tasks in parallel. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-grade, agent-native SDLC workflow template in this repository that guides development teams and autonomous AI agents through a 5-pass progressive expansion engine—iteratively expanding a system design level-by-level from macro domain intent to strict contracts, agent steering, Terraform IaC, and progressive GCP deployment.

**Architecture:** A 5-tier progressive expansion engine supporting a multi-tier microservices architecture (Frontend Web, API Backend, Background Worker, PostgreSQL, Cloud Pub/Sub) running on GCP Cloud Run serverless containers, governed by OpenAPI and Pub/Sub event contracts, managed via modular Terraform, and automated with GitHub Actions utilizing Workload Identity Federation (WIF) and MCP server tooling.

**Tech Stack:** Markdown/Mermaid, OpenAPI 3.1, JSON Schema, PostgreSQL DDL, Docker/Docker Compose, Terraform (GCP Provider), GitHub Actions, Workload Identity Federation, GCP Cloud Run v2, Cloud Pub/Sub, Cloud SQL, Cloud Monitoring/Logging, Model Context Protocol (MCP).

**Spec:** [`docs/superpowers/specs/2026-09-21-system-design-to-deployment-workflow-template-design.md`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/docs/superpowers/specs/2026-09-21-system-design-to-deployment-workflow-template-design.md)

## Global Constraints
- Progressive Elaboration: Each expansion pass must build strictly upon the verified outputs of the preceding pass.
- Every template document must include YAML frontmatter and clear placeholder annotations (`{{VARIABLE_NAME}}`) with complete accompanying explanation.
- No dummy/unusable code: all schema files, Dockerfiles, Terraform configs, and GitHub workflows must be syntactically valid and pass linter/validator checks.
- Zero raw secrets: all GCP authentication must use Workload Identity Federation (WIF) or Secret Manager; no plaintext service account keys.
- Docker containers must adhere to non-root least-privilege standards and multi-stage builds.
- All independent tasks within each pass are designed for parallel subagent dispatch via `superpowers:dispatching-parallel-agents`.

## Review Focus
1. Level-to-level alignment: Verify that entities defined in Pass 1 discovery trace directly into Pass 2 containers, Pass 3 contracts, Pass 4 services, and Pass 5 cloud resources.
2. Contract-to-Implementation drift: Ensure OpenAPI endpoints and Pub/Sub topic names match exactly across contracts, Terraform configs, and CI/CD pipelines.
3. Keyless WIF security: Ensure GitHub Actions workflows use OIDC tokens and omit static GCP credentials.
4. Private networking isolation: Ensure Cloud SQL and Cloud Run talk via Serverless VPC Connector without public IP database exposure.
5. Local vs Cloud parity: Ensure `docker-compose.yml` provides a functional local facsimile of the GCP cloud runtime.

---

## Pass 1: Macro Domain & System Context Expansion (Zoom Level 1)

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
  git commit -m "docs: add Pass 1 discovery and problem statement templates"
  ```

### Task 1.2: C4 System Context Model Template
**Files:**
- Create: `docs/01-architecture/c4-context-model.md`
- Create: `docs/01-architecture/README.md`

**Interfaces:**
- Consumes: Discovery templates from Task 1.1.
- Produces: C4 Level 1 Context diagrams establishing system boundaries and external actors.

- [ ] **Step 1: Write C4 System Context template**
  - Author `docs/01-architecture/c4-context-model.md` with interactive Mermaid C4 diagrams illustrating external users, external payment/auth systems, and high-level platform boundary.
  - Author `docs/01-architecture/README.md` outlining the progressive architectural zoom levels.
- [ ] **Step 2: Commit**
  ```bash
  git add docs/01-architecture/
  git commit -m "docs: add Pass 1 C4 system context model template"
  ```

---

## Pass 2: Service Topology & Communication Architecture Expansion (Zoom Level 2)

### Task 2.1: System Architecture RFC Template
**Files:**
- Create: `docs/01-architecture/system-rfc-template.md`

**Interfaces:**
- Consumes: System Context from Pass 1.
- Produces: Comprehensive architectural RFC template detailing synchronous REST flows, asynchronous event buffering, and security perimeters.

- [ ] **Step 1: Write System RFC template**
  - Detail sections: System Overview, High-Level Goals, Service Topology, Data Ingestion/Egress, Synchronous vs. Asynchronous patterns, Security, and Scalability.
- [ ] **Step 2: Commit**
  ```bash
  git add docs/01-architecture/system-rfc-template.md
  git commit -m "docs: add Pass 2 comprehensive system RFC template"
  ```

### Task 2.2: C4 Container Architecture Model Template
**Files:**
- Create: `docs/01-architecture/c4-container-model.md`

**Interfaces:**
- Consumes: RFC specifications.
- Produces: C4 Level 2 Container Mermaid diagram detailing Web Frontend, API Backend, Background Worker, PostgreSQL, and Cloud Pub/Sub.

- [ ] **Step 1: Author C4 Container diagram and communication matrix**
  - Build interactive Mermaid diagram showing protocols (HTTPS/JSON, Pub/Sub push, PostgreSQL TCP via VPC Connector).
- [ ] **Step 2: Commit**
  ```bash
  git add docs/01-architecture/c4-container-model.md
  git commit -m "docs: add Pass 2 C4 container architecture model template"
  ```

### Task 2.3: Architecture Decision Records (ADR) Framework
**Files:**
- Create: `docs/adr/README.md`
- Create: `docs/adr/template.md`
- Create: `docs/adr/0001-record-architecture-decisions.md`
- Create: `docs/adr/0002-cloud-run-serverless-microservices.md`

**Interfaces:**
- Consumes: Architecture trade-offs from RFC.
- Produces: Versioned ADR log recording technological decisions and trade-offs.

- [ ] **Step 1: Write ADR template and standard records**
  - Author `docs/adr/template.md` based on Nygard format (Status, Context, Decision, Consequences).
  - Create `docs/adr/0001-record-architecture-decisions.md` establishing the ADR pattern.
  - Create `docs/adr/0002-cloud-run-serverless-microservices.md` codifying Cloud Run + Pub/Sub selection over GKE.
- [ ] **Step 2: Commit**
  ```bash
  git add docs/adr/
  git commit -m "docs: add Pass 2 ADR framework and architectural records"
  ```

---

## Pass 3: Interface, Contract & Schema Expansion (Zoom Level 3)

### Task 3.1: OpenAPI 3.1 REST API Specification & Mock Contracts
**Files:**
- Create: `contracts/api/openapi.yaml`
- Create: `contracts/api/mock-server.json`
- Create: `contracts/api/README.md`

**Interfaces:**
- Consumes: C4 API component boundaries from Pass 2.
- Produces: Strict schema-anchored endpoints, request bodies, RFC 7807 problem details, and mock responses.

- [ ] **Step 1: Author OpenAPI 3.1 specification**
  - Define `/healthz`, `/api/v1/tasks` (CRUD), and `/api/v1/events` endpoints.
  - Include schemas with validation rules, examples, and standard HTTP error models.
- [ ] **Step 2: Provide mock server configuration and instructions**
  - Add `contracts/api/mock-server.json` for Prism or WireMock mocking.
- [ ] **Step 3: Validate and commit**
  ```bash
  git add contracts/api/
  git commit -m "feat: add Pass 3 OpenAPI 3.1 contracts and mock specifications"
  ```

### Task 3.2: Cloud Pub/Sub Event Schemas & Message Definitions
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
  git commit -m "feat: add Pass 3 CloudEvents-compliant Pub/Sub schemas"
  ```

### Task 3.3: Database DDL Schema & Entity Relationship Model
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
  git commit -m "feat: add Pass 3 database DDL schema and visual ERD"
  ```

---

## Pass 4: Agent Steering, Scaffolding & Task Expansion (Zoom Level 4)

### Task 4.1: Agent Context, Rules & Prompt Playbooks
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
  - Document repository topology, contract-first rules, coding conventions, testing requirements, and forbidden antipatterns.
- [ ] **Step 2: Create agent slash command playbooks**
  - Author reusable prompt workflows in `.agents/playbooks/`.
- [ ] **Step 3: Commit**
  ```bash
  git add AGENTS.md .cursorrules GEMINI.md .agents/
  git commit -m "feat: add Pass 4 agent steering rules and prompt playbooks"
  ```

### Task 4.2: Model Context Protocol (MCP) Integration Hub
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
  git commit -m "feat: add Pass 4 MCP server configuration hub and guides"
  ```

### Task 4.3: Containerized Scaffolding & Local Feedback Loop
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
  ```bash
  git add docker-compose.yml Makefile services/
  git commit -m "feat: add Pass 4 multi-tier container scaffolding and Makefile harness"
  ```

---

## Pass 5: IaC, Progressive CI/CD & Observability Expansion (Zoom Level 5)

### Task 5.1: GCP Terraform Modules & Environment Roots
**Files:**
- Create: `infra/modules/vpc/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/iam_wif/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/artifact_registry/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/cloud_run/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/cloud_sql/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/modules/pubsub/{main.tf, variables.tf, outputs.tf}`
- Create: `infra/environments/dev/{main.tf, variables.tf, terraform.tfvars.example}`
- Create: `infra/environments/staging/{main.tf, variables.tf, terraform.tfvars.example}`
- Create: `infra/environments/prod/{main.tf, variables.tf, terraform.tfvars.example}`
- Create: `infra/README.md`

**Interfaces:**
- Consumes: GCP Project ID and service parameters.
- Produces: Declarative infrastructure modules and environment roots.

- [ ] **Step 1: Author Terraform reusable modules (VPC, WIF, Artifact Registry, Cloud Run, Cloud SQL, Pub/Sub)**
- [ ] **Step 2: Author environment roots (dev, staging, prod) and variables**
- [ ] **Step 3: Commit**
  ```bash
  git add infra/
  git commit -m "feat: add Pass 5 Terraform modules and multi-environment roots"
  ```

### Task 5.2: GitHub Actions CI Pipeline with Security Scanning
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
  git commit -m "ci: add Pass 5 GitHub Actions CI pipeline with Trivy scanning"
  ```

### Task 5.3: GitHub Actions Progressive CD Pipelines (Staging & Prod)
**Files:**
- Create: `.github/workflows/deploy-staging.yaml`
- Create: `.github/workflows/deploy-prod.yaml`

**Interfaces:**
- Consumes: Approved merges to main/release tags.
- Produces: WIF-authenticated container pushes to Artifact Registry and Cloud Run revision deployments with traffic splitting.

- [ ] **Step 1: Author deploy-staging.yaml and deploy-prod.yaml**
- [ ] **Step 2: Commit**
  ```bash
  git add .github/workflows/deploy-*.yaml
  git commit -m "ci: add Pass 5 progressive CD pipelines with WIF and traffic splitting"
  ```

### Task 5.4: Production Observability, Alert Policies & Master Documentation
**Files:**
- Create: `monitoring/alert-policies.yaml`
- Create: `monitoring/logging-config.md`
- Create: `docs/03-operations/incident-runbook.md`
- Create: `docs/03-operations/slo-sli-definitions.md`
- Create: `README.md` (Top-level template guide)

**Interfaces:**
- Consumes: Telemetry standards and workflow template architecture.
- Produces: Alerting rules, SLO metrics, operational incident response procedures, and master repository documentation.

- [ ] **Step 1: Author alert policies and logging guide**
- [ ] **Step 2: Author incident runbook and SLO definitions**
- [ ] **Step 3: Author master README.md with 5-Pass Progressive Expansion Guide**
- [ ] **Step 4: Commit**
  ```bash
  git add monitoring/ docs/03-operations/ README.md
  git commit -m "feat: add Pass 5 observability, incident runbooks, and master README"
  ```
