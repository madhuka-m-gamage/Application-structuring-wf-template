---
id: "0001"
title: "Record Architecture Decisions in the Repository"
status: "Accepted"
date: "2026-09-21"
deciders:
  - "Platform Architecture Team"
  - "Lead Site Reliability Engineer"
  - "Autonomous Agent Framework Lead"
consulted:
  - "Core Development Team"
  - "Product Operations"
informed:
  - "All Engineering Contributors"
  - "Autonomous AI Agents (Antigravity, Claude Code, Cursor)"
supersedes: ""
superseded_by: ""
tags:
  - architecture
  - governance
  - adr
  - agent-native
  - pass-1
  - pass-2
---

# ADR-0001: Record Architecture Decisions in the Repository

## Status
![Status: Accepted](https://img.shields.io/badge/status-accepted-brightgreen.svg)
*Accepted on 2026-09-21*

---

## Context and Problem Statement

As this repository implements the **5-Pass Progressive Plan Expansion Architecture**, architectural decisions must bridge high-level domain discovery (Pass 1) through container topology (Pass 2), interface contracts (Pass 3), agent scaffolding (Pass 4), and cloud infrastructure (Pass 5).

Furthermore, development in this repository is heavily driven by **autonomous AI agents** (such as Antigravity, Claude Code, and Cursor) working alongside human software engineers. Without a structured, version-controlled architectural log:

1. **Agent Context Loss & Hallucinations**: AI agents operate in stateless execution sessions. When spun up on a task, an agent has no intrinsic memory of previous prompt interactions or unrecorded verbal discussions. Without explicit written constraints, agents repeatedly hallucinate new architectural patterns, suggest conflicting dependencies, or revert deliberate trade-offs.
2. **Tribal Knowledge & Architectural Erosion**: Decisions made in ephemeral channels (Slack discussions, meeting notes, PR descriptions) become invisible over time. Future contributors—both human and AI—lack the context of *why* a particular technology, pattern, or constraint was chosen.
3. **Review Fatigue**: Human reviewers must spend disproportionate effort explaining foundational architectural decisions repeatedly across pull requests.

We require a standardized, lightweight, and permanent method to record architectural decisions that is accessible to both humans and LLM agents directly within the repository.

---

## Decision Drivers

* **Driver 1: In-Repo Co-Location & Version Control**: Architecture records must live in the same Git tree as the codebase, evolving atomically alongside code and infrastructure changes via standard pull requests.
* **Driver 2: Agent Readability & Context Injection**: The format must be cleanly parsed by Large Language Models (LLMs) and agent file-reading tools with minimal token overhead and clear machine-readable metadata.
* **Driver 3: Historical Immutability & Auditability**: Once accepted, architectural records must remain immutable historical artifacts. Revisions must occur through explicit superseding records rather than silent in-place modification.
* **Driver 4: Low Cognitive Overhead**: The authoring process must be lightweight enough to encourage prompt documentation without imposing bureaucratic drag on velocity.
* **Driver 5: Alignment with 5-Pass SDLC**: Must serve as an explicit quality gate transitioning Pass 1 discovery into Pass 2 container topology and Pass 3 interface contracts.

---

## Considered Options

1. **Option 1: In-Repository Markdown ADRs (Michael Nygard format with YAML frontmatter) in `docs/adr/`**
2. **Option 2: External Documentation Platform (Confluence, Notion, or Google Docs)**
3. **Option 3: Inline Code Comments and Git Commit / Pull Request Descriptions Only**
4. **Option 4: Architectural Modeling Diagrams Only (C4 Diagrams in `docs/01-architecture/`)**

---

## Evaluation of Options

### Option 1: In-Repository Markdown ADRs (Nygard format with YAML Frontmatter)

*Store Architecture Decision Records as plain Markdown documents in `docs/adr/` numbered sequentially (`NNNN-title.md`), structured with Nygard sections (Context, Decision Drivers, Considered Options, Outcome, Consequences) and YAML frontmatter.*

* **Pros (+)**:
  * **+ Co-located with Code**: Decisions branch, merge, and diff alongside the code that implements them.
  * **+ Agent Native**: Agents can easily discover, read, and cross-reference records using standard file-view tools without external API keys or browser automation.
  * **+ Immutable Provenance**: Git history provides cryptographic traceability of who proposed, reviewed, and merged each architectural decision.
  * **+ Frontmatter Parsing**: Machine-readable metadata (`status`, `date`, `deciders`, `tags`, `supersedes`) allows automated CI linters to validate compliance.
* **Cons (-)**:
  * **- Discoverability for Non-Technical Stakeholders**: Non-developer business stakeholders must browse Git or a rendered Markdown viewer.
  * **- Discipline Requirement**: Requires code review enforcement to ensure contributors update and maintain the index.
* **Cost & Operational Profile**:
  * *Cost*: \$0 (Zero additional infrastructure or SaaS subscription cost).
  * *Operational Burden*: Minimal; managed entirely through existing Git workflows.

### Option 2: External Documentation Platform (Confluence, Notion, Google Docs)

*Document architectural choices in a centralized external enterprise wiki or knowledge management workspace.*

* **Pros (+)**:
  * **+ Rich WYSIWYG Collaboration**: Real-time multi-user cursor editing and accessible to non-technical stakeholders.
  * **+ Built-in Search**: Enterprise full-text indexing across the organization.
* **Cons (-)**:
  * **- Disconnected from Code**: Inevitable documentation drift occurs as code is updated in Git while external docs remain stale.
  * **- Inaccessible to Autonomous Agents**: Coding agents in isolated workspaces or sandboxes cannot easily query external private wikis without specialized MCP tools, credentials, and network ingress.
  * **- No Atomic PR Gates**: Cannot block a code change in CI if an architectural decision has not been approved in an external tool.
* **Cost & Operational Profile**:
  * *Cost*: Monthly per-seat SaaS license fees.
  * *Operational Burden*: High (managing IAM permissions, OAuth tokens, and synchronization between Git and external wiki).

### Option 3: Inline Code Comments and Pull Request Summaries Only

*Rely on developers and agents writing thorough comments in source files and summarizing architecture rationale in GitHub PR descriptions.*

* **Pros (+)**:
  * **+ Zero Setup**: No dedicated directory or template files required.
* **Cons (-)**:
  * **- Fragmented & Ephemeral**: PR descriptions are detached from the primary file tree and difficult for agents to query efficiently across historical branches.
  * **- Lack of Comparative Rationale**: Code comments explain *what* the code does, but rarely capture the *rejected alternatives* and trade-off matrices.
  * **- No Architectural Gate**: Impossible to validate architectural compliance systematically before code is authored.
* **Cost & Operational Profile**:
  * *Cost*: \$0.
  * *Operational Burden*: Extreme cognitive debt; high risk of repeated architectural regressions.

### Option 4: Architectural Modeling Diagrams Only (C4 Diagrams in `docs/01-architecture/`)

*Rely exclusively on Mermaid C4 diagrams (Context, Container, Component) in `docs/01-architecture/` without narrative decision records.*

* **Pros (+)**:
  * **+ High Visual Clarity**: Excellent at depicting structural topologies and network communication paths.
* **Cons (-)**:
  * **- Missing the "Why"**: A diagram displays the resulting topology (e.g., Cloud Run &rarr; Cloud SQL), but cannot articulate why GKE or GCE was rejected, what cost trade-offs were accepted, or what mitigations exist for cold starts.
  * **- Insufficient Granularity**: Diagrams cannot capture subtle decisions such as authentication strategies, pagination semantics, or idempotency keys.
* **Cost & Operational Profile**:
  * *Cost*: \$0.
  * *Operational Burden*: High ambiguity for implementing agents.

---

## Comparison Matrix

| Evaluation Criteria | Option 1: In-Repo Markdown ADRs | Option 2: External Wiki | Option 3: PR Descriptions / Comments | Option 4: Diagrams Only |
|---|:---:|:---:|:---:|:---:|
| **Git Co-Location & Versioning** | **Excellent** | Poor | Fair | **Excellent** |
| **Agent Accessibility & Ingestion** | **Excellent** | Poor | Poor | Good |
| **Captures Rejected Alternatives** | **High** | High | Low | Very Low |
| **Enforceable in CI / Reviews** | **Yes** | No | No | Partial |
| **Tooling & Maintenance Cost** | **Zero (\$0)** | Recurring SaaS | Zero (\$0) | Zero (\$0) |
| **Driver Alignment Score** | **High (5/5)** | Low (2/5) | Low (1/5) | Medium (3/5) |

---

## Decision Outcome

**Chosen Option**: **Option 1: In-Repository Markdown ADRs in `docs/adr/` using the Michael Nygard format with YAML frontmatter.**

### Justification and Rationale
1. **Agent First**: Storing ADRs in `docs/adr/` allows AI agents to scan the directory at the start of any planning or refactoring phase. Agents can read the decisions in sub-second time, absorb the architectural invariants, and avoid hallucinating conflicting patterns.
2. **Atomic Versioning**: When an architectural shift occurs, the ADR change is bundled in the exact same Git pull request as the corresponding contract updates (Pass 3) and infrastructure definitions (Pass 5).
3. **Nygard Standardization**: The Michael Nygard structure is globally recognized across the software industry, ensuring instant familiarity for incoming human engineers and well-established training priors for LLMs.

---

## Positive and Negative Consequences

### Positive Consequences
* **Architectural Invariant Enforcement**: Decisions become enforceable constraints during PR reviews and agent task planning.
* **Preservation of Institutional Memory**: Rationale, rejected alternatives, and anticipated risks are permanently preserved in Git blame and commit history.
* **Structured Evolution via Supersession**: Obsolete decisions are never silently altered; they are superseded by new ADRs, providing an unbroken evolutionary timeline.
* **Seamless 5-Pass Integration**: ADRs directly bridge Pass 1 domain requirements into Pass 2 container topology and Pass 3 contracts.

### Negative Consequences
* **Authoring Overhead**: Creating an ADR requires time and thoughtful evaluation of rejected alternatives before writing code.
* **Maintenance Discipline**: The team must maintain the ADR index in `docs/adr/README.md` and ensure old ADRs are marked `Superseded` when replaced.

### Risk Mitigations
* **Template Standardization**: We provide `docs/adr/template.md` with pre-populated sections and clear instructions to minimize authoring friction.
* **Agent Automation**: AI agents are instructed in `AGENTS.md` to draft proposed ADRs autonomously whenever significant architectural changes are contemplated.
* **Markdown Validation in CI**: Markdown linters in CI verify that all ADR files parse cleanly and adhere to header conventions.

---

## Implementation Plan & Downstream Impact

* **Directory Setup**: Create `docs/adr/` containing:
  - `README.md` (governance rules, agent instructions, master index).
  - `template.md` (standard template for all future records).
  - `0001-record-architecture-decisions.md` (this foundational record).
* **Agent Instructions**: Integrate ADR authoring rules into `AGENTS.md` (Pass 4 deliverable), mandating that agents review `docs/adr/` prior to writing code.
* **Downstream Alignment**: All subsequent architectural decisions (such as ADR-0002 for compute/messaging/storage selection) will follow this exact standard.

---

## Compliance & Invariant Checklist

- [x] ADR directory initialized at `docs/adr/`.
- [x] Standard template created at `docs/adr/template.md`.
- [x] Foundational ADR-0001 authored and marked `Accepted`.
- [x] Master index updated in `docs/adr/README.md`.
- [x] Git commits reflect clean addition of architectural governance assets.
