# Service Level Objectives (SLO) & Indicators (SLI) Specification

> **Pass 5 Artifact**: Observability, Telemetry & Operations (Zoom Level 5)  
> **Target Framework**: Site Reliability Engineering (SRE) / Google Cloud Monitoring  
> **Status**: Active & Authoritative  
> **Last Updated**: 2026-09-21

---

## 1. Executive Summary & Core SRE Concepts

This document establishes the formal reliability targets, quantitative Service Level Indicators (SLIs), Service Level Objectives (SLOs), and automated error budget policies for the System Design-to-Deployment platform.

### Conceptual Hierarchy
- **Service Level Indicator (SLI)**: A carefully defined quantitative metric measuring service level provided (e.g., successful requests / valid requests).
- **Service Level Objective (SLO)**: A target reliability percentage for an SLI over a rolling compliance window (e.g., 99.9% over 30 days).
- **Service Level Agreement (SLA)**: A contractual commitment to external customers with financial penalties if breached. (SLO targets are strictly tighter than external SLAs).
- **Error Budget**: The tolerated unreliability over a compliance window:
  $$\text{Error Budget} = 100\% - \text{SLO}$$
  For a 99.9% SLO over a 30-day rolling window:
  $$\text{Error Budget} = 0.1\% = 43.2 \text{ minutes of downtime or } 1 \text{ failed request per } 1,000 \text{ requests.}$$

---

## 2. Quantitative SLO Target Catalog

| Service Component | Metric / Concern | SLI Definition | SLO Target | Compliance Window |
|---|---|---|---|---|
| **API Gateway** (`services/api`) | **Availability** | Proportion of valid HTTP requests returning non-5xx status codes. | **$\ge$ 99.9%** | 30-day rolling |
| **API Gateway** (`services/api`) | **Latency (Fast Tier)** | Proportion of valid HTTP requests completed in $\le$ 200ms. | **$\ge$ 95.0%** | 30-day rolling |
| **API Gateway** (`services/api`) | **Latency (Tail Tier)** | Proportion of valid HTTP requests completed in $\le$ 1,000ms. | **$\ge$ 99.0%** | 30-day rolling |
| **Background Worker** (`services/worker`) | **Event Freshness** | Proportion of Pub/Sub task events processed within $\le$ 5.0 seconds of emission. | **$\ge$ 99.0%** | 30-day rolling |
| **Persistence Tier** (`postgres`) | **Transaction Durability** | Proportion of outbox events written without uncommitted data loss. | **100%** | Continuous |

---

## 3. Formal SLI Mathematical Formulations & Monitoring Queries

### 3.1 SLI 1: API Availability
$$\text{SLI}_{\text{avail}} = \frac{\sum \text{Requests}(\text{status} < 500)}{\sum \text{Requests}(\text{all status codes excluding client-side timeouts})}$$

#### Google Cloud Monitoring MQL (Monitoring Query Language):
```mql
fetch cloud_run_revision
| metric 'run.googleapis.com/request_count'
| filter (resource.service_name == 'template-api')
| group_by [response_code_class], [row_count: count()]
| every 1m
| {
    filter response_code_class != '5xx' ;
    ident
  }
| ratio
```

---

### 3.2 SLI 2: API Request Latency (p95 < 200ms, p99 < 1000ms)
$$\text{SLI}_{\text{latency\_fast}} = \frac{\sum \text{Requests}(\text{latency} \le 200\text{ms})}{\sum \text{Total Valid Requests}}$$
$$\text{SLI}_{\text{latency\_tail}} = \frac{\sum \text{Requests}(\text{latency} \le 1000\text{ms})}{\sum \text{Total Valid Requests}}$$

#### Google Cloud Monitoring MQL:
```mql
fetch cloud_run_revision
| metric 'run.googleapis.com/request_latencies'
| filter (resource.service_name == 'template-api')
| align delta(1m)
| every 1m
| group_by [resource.service_name],
    [p95: percentile(val(), 95),
     p99: percentile(val(), 99)]
```

---

### 3.3 SLI 3: Asynchronous Event Processing Freshness
$$\text{SLI}_{\text{freshness}} = \frac{\sum \text{Events}(\text{worker\_ack\_time} - \text{event\_publish\_time} \le 5\text{s})}{\sum \text{Total Processed Events}}$$

#### Google Cloud Monitoring Metric:
- Filter: `resource.type="pubsub_subscription" AND resource.labels.subscription_id="worker-task-created-sub"`
- Metric: `pubsub.googleapis.com/subscription/oldest_unacked_message_age` $\le 5\text{s}$.

---

## 4. Error Budget Burn Rate Mathematics & Multi-Window Alerting

Rather than alerting only when an error budget is completely exhausted (which happens too late), the platform utilizes **Multi-Window Multi-Burn-Rate Alerting** as standardized in the Google SRE Handbook.

### Burn Rate Definition
Burn rate is the rate at which a service consumes its error budget relative to its normal 30-day pace:
- **Burn Rate = 1.0**: The service will consume exactly 100% of its error budget over the 30-day window.
- **Burn Rate = 14.4**: The service will consume **2% of its entire monthly error budget in just 1 hour**.
- **Burn Rate = 6.0**: The service will consume **5% of its entire monthly error budget in 6 hours**.

$$\text{Burn Rate} = \frac{\text{Observed Error Rate}}{1 - \text{SLO}} = \frac{\text{Observed Error Rate}}{0.001}$$

### Multi-Window Alerting Matrix

| Alert Tier | Severity | Burn Rate | % Budget Consumed | Short Window | Long Window | Notification Target | Action Required |
|---|---|---|---|---|---|---|---|
| **Tier 1** | **CRITICAL (P1)** | **14.4x** | 2.0% in 1 hour | 5 minutes | 1 hour | PagerDuty (On-Call Engineer) | Immediate page, halt ongoing rollouts, execute instant rollback. |
| **Tier 2** | **HIGH (P2)** | **6.0x** | 5.0% in 6 hours | 30 minutes | 6 hours | PagerDuty (On-Call Engineer) | Triage investigation within 15 minutes, scale resources or rollback. |
| **Tier 3** | **MEDIUM (P3)** | **2.5x** | 10.0% in 36 hours | 2 hours | 36 hours | Slack (`#alerts-reliability`) | Investigate next business day, open tracking defect. |
| **Tier 4** | **LOW (P4)** | **1.0x** | 10.0% in 3 days | 6 hours | 3 days | Email / Jira Auto-Ticket | Reliability review in weekly sprint planning. |

---

## 5. Release Freeze & Reliability Escalation Policies

Error budgets represent the acceptable rate of innovation risk. When reliability degrades, the platform enforces automated policy escalation:

```mermaid
flowchart TD
    A["Remaining Error Budget > 50%<br/><b>State: Normal</b>"] -->|Budget drops below 50%| B["Remaining Error Budget: 25% - 50%<br/><b>State: Elevated Caution</b>"]
    B -->|Budget drops below 25%| C["Remaining Error Budget: 0% - 25%<br/><b>State: Orange Guardrail</b>"]
    C -->|Budget exhausted (<= 0%)| D["Remaining Error Budget: <= 0%<br/><b>State: Hard Release Freeze</b>"]

    A -.->|Action| A1["Regular feature shipping.<br/>Standard canary deployments."]
    B -.->|Action| B1["Canary bake time doubled (30m).<br/>Non-essential background jobs throttled."]
    C -.->|Action| C1["All experimental flags disabled.<br/>Senior architect sign-off required for deploys."]
    D -.->|Action| D1["ALL non-critical deployments blocked.<br/>100% engineering effort redirected to reliability."]
```

### 5.1 Policy Tiers

#### Tier 1: Normal Operations (Budget Remaining > 50%)
- Feature deployments proceed through standard CI/CD with progressive canary rollout (10% $\to$ 50% $\to$ 100%).
- Full velocity across all engineering streams.

#### Tier 2: Elevated Caution (Budget Remaining 25% – 50%)
- Canary deployment observation window ("bake time") is increased from 15 minutes to 30 minutes.
- Architectural modifications and high-risk schema migrations require dual-peer review.

#### Tier 3: Orange Guardrail (Budget Remaining 1% – 25%)
- Any non-bug-fix PR requires explicit approval from the Platform Tech Lead or SRE Commander.
- A/B testing and experimental traffic flags are locked.

#### Tier 4: Hard Release Freeze (Budget Exhausted $\le$ 0%)
- **Automated CI/CD Block**: GitHub Actions deployment pipelines to Production are locked via environment protection rules.
- **Emergency Exceptions Only**: Only hotfixes that directly resolve the identified reliability defect and restore the SLI may be deployed.
- **Reliability Sprint**: All upcoming feature roadmap commitments are postponed until the 30-day rolling compliance window clears and error budget restores to $\ge$ 50%.

---

## 6. SLO Reporting & Governance Cadence

1. **Daily Telemetry Review**: Automated Slack report posted every morning to `#engineering-reliability` with current 30-day rolling SLIs and remaining error budget percentages.
2. **Weekly SRE Review**: Engineering managers and tech leads inspect services with burn rates $> 1.0\text{x}$.
3. **Monthly Retrospective**: Platform reliability post-mortem and adjustments to SLO thresholds based on business requirements.
