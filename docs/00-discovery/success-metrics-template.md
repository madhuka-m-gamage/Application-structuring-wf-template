---
title: "Success Metrics & SLO Framework: {{SYSTEM_NAME}}"
author: "{{AUTHOR_NAME_OR_AGENT}}"
date: "{{DATE_YYYY_MM_DD}}"
status: "DRAFT" # Options: DRAFT | IN_REVIEW | APPROVED | REVISED
version: "1.0.0"
pass: "Pass 1: Macro Domain & System Context Expansion"
zoom_level: "Zoom Level 1"
tags:
  - discovery
  - success-metrics
  - kpi
  - slo-sli
  - error-budget
  - dora-metrics
  - definition-of-done
---

<!--
================================================================================
INSTRUCTIONS FOR AUTHORS AND AI CODING AGENTS
================================================================================
This document defines the quantitative success metrics, Service Level Objectives
(SLOs), Service Level Indicators (SLIs), Error Budgets, and the Definition of
Done (DoD) for {{SYSTEM_NAME}}.

AI AGENT STEERING:
1. Ground all metrics in tangible numbers; do not leave subjective goals.
2. The availability baseline is standard 99.9% ("Three Nines") unless explicitly
   overridden by customer SLA requirements.
3. Every SLI defined in Section 4 must have a corresponding telemetry metric name
   identifiable in Google Cloud Monitoring or OpenTelemetry.
4. The Definition of Done (DoD) in Section 5 acts as the programmatic verification
   gate before expanding into Pass 2 (Architecture & Container Modeling).
================================================================================
-->

# Success Metrics & SLO Framework: {{SYSTEM_NAME}}

<!-- @agent-meta: {"phase": "pass-1", "artifact": "success-metrics", "system": "{{SYSTEM_NAME}}", "baseline_slo": 0.999, "version": "1.0.0"} -->

## 1. Metrics Strategy & Progressive Expansion Traceability

In the 5-Pass Progressive Expansion Engine, success metrics are not static post-mortems; they form the operational steering vectors that govern downstream architectural and deployment choices:
* **Pass 2 (Topology)**: Latency and throughput targets dictate synchronous vs. asynchronous service boundaries.
* **Pass 3 (Contracts)**: Error formats (RFC 7807) and retry headers are parameterized to support SLI collection.
* **Pass 4 (Implementation)**: Local health checks and benchmarks enforce the performance envelope before code merge.
* **Pass 5 (IaC & Observability)**: Cloud Monitoring alert policies and automated rollback triggers are generated directly from the SLO thresholds specified in this document.

---

## 2. Business Key Performance Indicators (KPIs)

Business KPIs quantify the economic and user-value justification for building {{SYSTEM_NAME}}.

### 2.1 Primary Business Outcome Metrics
<!-- @schema:business-kpi-table -->
| KPI Identifier | Metric Name | Business Intent | Current Baseline | Target Threshold (30d) | Target Threshold (180d) | Measurement Method & Source |
|---|---|---|---|---|---|---|
| `BKPI-01` | Transaction Conversion Rate | Measure end-to-end task completion without client abandon | `{{BKPI_01_BASELINE}}%` | `>= {{BKPI_01_TARGET_30D}}%` | `>= {{BKPI_01_TARGET_180D}}%` | Analytics warehouse / Cloud SQL query |
| `BKPI-02` | Cost per Transaction | Unit economic efficiency of cloud serverless resources | `\${{BKPI_02_BASELINE}}` | `<=\${{BKPI_02_TARGET_30D}}` | `<=\${{BKPI_02_TARGET_180D}}` | Google Cloud Billing exports / requests |
| `BKPI-03` | User Task Execution Time | Speed at which users achieve their desired business outcome | `{{BKPI_03_BASELINE}} mins` | `<={{BKPI_03_TARGET_30D}} mins` | `<={{BKPI_03_TARGET_180D}} mins` | Application event timing telemetry |
| `BKPI-04` | Operational Overhead Ratio | Engineering hours spent on manual fixes per 10k transactions | `{{BKPI_04_BASELINE}} hrs` | `<={{BKPI_04_TARGET_30D}} hrs` | `<={{BKPI_04_TARGET_180D}} hrs` | Issue tracking & on-call logging |

### 2.2 Customer Satisfaction & Experience Metrics
* **System Usability Scale (SUS) / CSAT**: Target score `>= {{TARGET_CSAT_SCORE}}` out of 100.
* **Client Drop-off Rate during Async Ingestion**: `< {{MAX_ALLOWED_DROP_OFF_PERCENT}}%`.
* **API Consumer Developer Experience (DX)**: Time to first successful API 200/202 response for new integrators `< {{TARGET_TIME_TO_FIRST_CALL_MINS}} minutes`.

---

## 3. Operational & DORA Metrics

Operational excellence is measured via industry-standard DORA (DevOps Research and Assessment) metrics and incident response SLAs.

### 3.1 DORA Performance Targets
<!-- @schema:dora-metrics-table -->
| DORA Dimension | Low Performer | Target Baseline (Medium/High) | Elite Goal | {{SYSTEM_NAME}} Target Commitment |
|---|---|---|---|---|
| **Deployment Frequency** | Monthly to bi-annually | Weekly to bi-weekly | On-demand (multiple/day) | **>= {{TARGET_DEPLOYMENT_FREQUENCY_PER_DAY}} deploys/day to Staging; On-demand to Prod** |
| **Lead Time for Changes** | 1 to 6 months | 1 week to 1 month | < 1 hour | **< {{TARGET_LEAD_TIME_HOURS}} hours (commit to live in production)** |
| **Change Failure Rate (CFR)** | 46% – 60% | 16% – 30% | 0% – 15% | **< {{TARGET_CHANGE_FAILURE_RATE_PERCENT}}% of production releases requiring rollback** |
| **Mean Time to Resolution (MTTR)**| > 1 week | 1 day to 1 week | < 1 hour | **< {{TARGET_MTTR_MINUTES}} minutes for critical production incidents** |

### 3.2 Incident Severity & Response SLAs
<!-- @schema:incident-sla-matrix -->
| Severity Level | Definition | Target Acknowledgment (MTTA) | Target Mitigation / Rollback (MTTR) | Communication Cadence |
|---|---|---|---|---|
| **Sev 1 (Critical)** | Outage affecting > 5% of active users, total API downtime, or data loss risk | `< 5 minutes` | `< 15 minutes` (Automated Canary Rollback) | Every 15 minutes to Incident Room |
| **Sev 2 (Major)** | Core degraded functionality; p99 latency > 2x target; DLQ spike > 1,000 items | `< 15 minutes` | `< 45 minutes` | Every 30 minutes |
| **Sev 3 (Minor)** | Non-blocking edge bug; localized UI glitch; background job queue delay < 10 mins | `< 2 hours` | `< 1 business day` | Daily standup |
| **Sev 4 (Low)** | Trivial defect, minor doc error, cosmetic formatting inconsistency | Next sprint | Next planned release cycle | Backlog triage |

---

## 4. Service Level Objectives (SLOs), SLIs & Error Budgets

### 4.1 99.9% Baseline Philosophy
For {{SYSTEM_NAME}}, the target service availability baseline is established at **99.9% ("Three Nines")** across rolling 30-day windows.
* **Why 99.9%?**: Provides an optimal balance between high availability (99.9% uptime = 43.8 minutes allowable downtime/month) and high velocity of deployment for feature iteration.
* **Cost Factor**: Moving from 99.9% to 99.99% ("Four Nines") incurs a 5x–10x infrastructure and engineering cost multiplier (requiring active-active multi-region failover and complex distributed consensus).

```
Three Nines (99.9%) Downtime Allowances:
+-------------------+---------------------------+
| Time Window       | Max Allowable Downtime    |
+-------------------+---------------------------+
| Daily (24 hours)  | 1 minute 26 seconds       |
| Weekly (7 days)   | 10 minutes 4 seconds      |
| Monthly (30 days) | 43 minutes 12 seconds     |
| Annual (365 days) | 8 hours 45 minutes 57 sec |
+-------------------+---------------------------+
```

---

### 4.2 Service Level Indicators (SLIs) Formulation

#### SLI 1: API Availability Indicator
* **Definition**: The proportion of valid HTTP requests that return successful (non-5xx) status codes.
$$\text{SLI}_{\text{Availability}} = \frac{\sum \text{Valid HTTP Responses with Status } < 500}{\sum \text{Total Valid HTTP Requests}} \times 100$$
* **Excluded**: Requests rejected due to client error (4xx: bad input, 401 unauthenticated, 429 rate limited), and requests hitting malformed routing.
* **Measurement Telemetry**: Google Cloud Run metric `run.googleapis.com/request_count` grouped by `response_code_class`.

#### SLI 2: API Latency Indicator
* **Definition**: The proportion of valid HTTP requests served faster than the designated latency threshold.
$$\text{SLI}_{\text{Latency}} = \frac{\sum \text{Requests served in } \le {{LATENCY_SLO_THRESHOLD_MS}}\text{ ms}}{\sum \text{Total Valid HTTP Requests}} \times 100$$
* **Target Baseline**: `99.0%` of requests completed in `<= {{LATENCY_SLO_THRESHOLD_MS}} ms` (e.g., 250ms).
* **Measurement Telemetry**: Cloud Run `run.googleapis.com/request_latencies` (distribution cutoff at designated percentile).

#### SLI 3: Asynchronous Message Ingestion & Durability Indicator
* **Definition**: The proportion of messages published to Cloud Pub/Sub that are successfully acknowledged or routed to Dead-Letter Queue (DLQ) without unrecoverable loss.
$$\text{SLI}_{\text{Durability}} = \frac{\sum \text{Acked Messages} + \sum \text{DLQ Messages}}{\sum \text{Published Messages}} \times 100 = 100.0\%$$
* **Measurement Telemetry**: Cloud Pub/Sub `pubsub.googleapis.com/subscription/ack_message_count` vs `dead_letter_message_count`.

---

### 4.3 SLO & Error Budget Specification Matrix

<!-- @schema:slo-specification-table -->
| SLO ID | Indicator Name | Target SLO | Compliance Window | Total Error Budget | Alerting Burn Rates | Telemetry Source Metric |
|---|---|---|---|---|---|---|
| `SLO-AVAIL-01` | Ingestion API Availability | **99.9%** | Rolling 30 Days | 0.1% (1 in 1,000 requests) | 14.4x (2% budget in 1 hr)<br/>6x (5% budget in 6 hrs) | `run.googleapis.com/request_count` |
| `SLO-LAT-01` | Read Endpoint Latency | **95.0%** `<= 150ms`<br/>**99.0%** `<= 300ms` | Rolling 7 Days | 1.0% above 300ms | 10x over 2 hours | `run.googleapis.com/request_latencies` |
| `SLO-LAT-02` | Ingestion Write Latency | **99.5%** `<= 200ms` (202 Accepted) | Rolling 30 Days | 0.5% above 200ms | 14.4x over 1 hour | `run.googleapis.com/request_latencies` |
| `SLO-ASYNC-01`| Background Worker Delivery | **99.9%** within `<= 5s` | Rolling 30 Days | 0.1% slower than 5s | 5x over 6 hours | Custom OpenTelemetry Span Duration |
| `SLO-ERR-01` | Dead-Letter Queue Leakage | **0 lost msgs** | Rolling 30 Days | 0 unhandled drops | Instant alert on unroutable message | `pubsub.googleapis.com/subscription/dead_letter_message_count` |

---

### 4.4 Error Budget Policy & Burn Rate Rules

When an error budget is consumed prematurely, automated operational guardrails take effect:

1. **Burn Rate Tiers**:
   - **Critical (14.4x Burn Rate)**: Consumes 2% of monthly budget in 1 hour. Action: PagerDuty page to primary on-call; automated freeze on non-emergency deployments.
   - **High (6x Burn Rate)**: Consumes 5% of monthly budget in 6 hours. Action: Incident ticket dispatched; review recent canary deployments.
   - **Low (1x Burn Rate)**: Steady-state budget consumption. Action: Logged to weekly observability report.
2. **Budget Exhaustion Consequence**:
   - If rolling 30-day error budget falls to **0% (100% consumed)**:
     - **Feature Release Freeze**: All non-security pull requests and feature merges are halted.
     - **Reliability Sprint**: Next development cycle is dedicated 100% to technical debt remediation, bug fixing, test suite enhancement, and infrastructure resilience.
     - **Resumption Condition**: Error budget recovery above 20% healthy threshold for 7 consecutive days.

---

## 5. Definition of Done (DoD) Checklist for Design Phase

This Definition of Done is the **mandatory exit gate** that validates completion of Pass 1 (Discovery & Intent) before any subagent or human engineer may proceed to Pass 2 (Service Topology & Architecture).

<!-- @schema:definition-of-done-checklist -->
### Category 1: Intent & Scope Clarity
- [ ] Problem Statement (`problem-statement-template.md`) completed with all double-curly bracket placeholders (`{{...}}`) fully replaced by domain-specific content.
- [ ] At least two distinct user personas (Primary Consumer and Operational/SRE) formalized with concrete background, goals, and pain points.
- [ ] At least four Jobs To Be Done (`JTBD`) written in canonical *"When... I want to... So I can..."* syntax.
- [ ] In-Scope vs. Out-of-Scope boundaries established with unambiguous non-goals to prevent autonomous agent hallucination and scope creep.

### Category 2: Metrics & Non-Functional Rigor
- [ ] All Non-Functional Requirements (NFRs) expressed as mathematical thresholds (e.g. `p99 <= 200ms`, `RPS >= 500`) without subjective adjectives ("fast", "scalable", "responsive").
- [ ] Baseline Availability SLO anchored at 99.9% ("Three Nines") with corresponding allowable downtime calculated.
- [ ] Target DORA metrics defined (Deployment frequency, Lead time < 2 hours, MTTR < 15 mins, Change failure rate < 5%).
- [ ] Mathematical equations for each Service Level Indicator (SLI) documented with exact telemetry metric source mappings in Google Cloud Monitoring.
- [ ] Error Budget Policy and Burn Rate escalation paths established with explicit feature freeze protocols.

### Category 3: Stakeholder & Agent Verification
- [ ] Assumptions, external dependencies, and open questions cataloged with assigned owners and due dates.
- [ ] No unaddressed high-severity blocking questions remaining in the investigation log.
- [ ] Automated markdown linting and schema validation checks pass without errors.
- [ ] Formal sign-off recorded in the Pass 1 approval matrix.

---

## 6. Pass 1 Sign-Off & Verification Stamp

<!-- @schema:pass-1-verification-stamp -->
```json
{
  "pass": 1,
  "zoom_level": "Zoom Level 1",
  "status": "APPROVED",
  "system_name": "{{SYSTEM_NAME}}",
  "approved_by": "{{LEAD_ARCHITECT_OR_HUMAN_IN_THE_LOOP}}",
  "verification_timestamp": "{{ISO8601_TIMESTAMP}}",
  "exit_gate_verified": true,
  "ready_for_pass_2": true
}
```
