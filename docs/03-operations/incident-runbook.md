# Production Incident Response & Recovery Runbook

> **Pass 5 Artifact**: Observability, Telemetry & Operations (Zoom Level 5)  
> **Target Audience**: SREs, On-Call Engineers, Platform Architects, Autonomous Agents  
> **Status**: Active & Authoritative  
> **Last Updated**: 2026-09-21

---

## 1. Incident Severity Classification & Triage Protocol

When an alert fires or abnormal behavior is reported, classify the incident immediately using this standard severity matrix:

| Severity | Definition | Target Response (MTTA) | Target Resolution (MTTR) | Communication Cadence |
|---|---|---|---|---|
| **P1 / Sev-1** | **Critical Outage**: Total API unavailability, data corruption, or core business path down for > 50% users. | < 5 minutes | < 30 minutes | Status update every 15 minutes |
| **P2 / Sev-2** | **Major Degradation**: Elevated latency (> 1000ms), partial feature failure, or worker backlog accumulating rapidly. | < 15 minutes | < 2 hours | Status update every 30 minutes |
| **P3 / Sev-3** | **Minor Defect**: Non-critical background delay, localized non-blocking error, or internal admin tool degradation. | < 60 minutes | < 24 hours | Daily update |
| **P4 / Sev-4** | **Cosmetic / Minor Bug**: Low impact, workaround available. | Next business day | Scheduled sprint | Ticket tracking |

---

## 2. P1 / Sev-1 Incident Triage Protocol

### Step 1: Declare Incident & Establish Incident Command
1. Designate the **Incident Commander (IC)**: Holds decision authority and coordinates all responders.
2. Designate the **Technical Lead (TL)**: Leads diagnostic and remediation actions.
3. Designate the **Communications Lead (CL)**: Posts external status updates and notifies stakeholders.
4. Spin up the Dedicated War Room (Google Meet or `#incident-warroom` Slack channel).
5. Post initial notification on internal incident dashboard and customer status page:
   > *"We are actively investigating elevated error rates affecting the API service. Further updates will be provided within 15 minutes."*

### Step 2: Immediate Assessment & Containment (First 10 Minutes)
1. **Identify the Trigger**: Was there a recent deployment, configuration change, secret rotation, or traffic surge?
   ```bash
   # Check recent Cloud Run revisions and deployment timestamps
   gcloud run revisions list --service=template-api --region=us-central1 --limit=5
   ```
2. **Review System Health Dashboard**:
   - HTTP 5xx error rate on `template-api`
   - p99 request latency
   - Cloud SQL CPU & connection pool utilization
   - Pub/Sub Dead-Letter Queue (DLQ) depth
3. **Execute Containment / Rollback**: If errors began directly after a deployment, proceed immediately to **Section 3: Cloud Run Instant Revision Rollback**. Do NOT spend time debugging failing code in production before rolling back.

---

## 3. Cloud Run Instant Revision Rollback SOP

Cloud Run maintains an immutable history of revisions. When a bad deployment causes regressions, traffic can be redirected 100% to a previously known healthy revision in less than 5 seconds without container rebuilding.

### 3.1 Inspect Active Traffic Split
```bash
# Display currently serving revisions and traffic percentages
gcloud run services describe template-api \
  --region=us-central1 \
  --format="table(status.traffic[].revisionName, status.traffic[].percent)"
```

### 3.2 Execute Zero-Downtime Rollback
Identify the last known healthy revision (e.g. `template-api-00042-xyz`) and route 100% of production traffic to it:

```bash
# Shift 100% of traffic immediately to the healthy revision
gcloud run services update-traffic template-api \
  --region=us-central1 \
  --to-revisions=template-api-00042-xyz=100
```

*For Worker Service:*
```bash
gcloud run services update-traffic template-worker \
  --region=us-central1 \
  --to-revisions=template-worker-00028-abc=100
```

### 3.3 Verify Rollback Success
1. **Check Service Endpoint**:
   ```bash
   curl -I https://api.production.domain.com/healthz
   # Expect: HTTP/1.1 200 OK
   ```
2. **Observe Error Rate Metrics**:
   Verify in Cloud Monitoring that the 5xx error rate drops to < 0.1% within 2 minutes.
3. **Review Log Stream for the Active Revision**:
   ```bash
   gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.revision_name="template-api-00042-xyz" AND severity>=WARNING' --limit=20
   ```

---

## 4. Pub/Sub Dead-Letter Queue (DLQ) Replay Procedure

When the asynchronous worker cannot process an event after 5 delivery attempts, Cloud Pub/Sub routes the unacknowledged message to the Dead-Letter Queue topic (`tasks-dlq`) and subscription (`tasks-dlq-sub`).

### 4.1 Inspecting DLQ Messages (Non-Destructive)
Pull up to 5 dead-lettered messages to examine error payloads without acknowledging them:

```bash
# Pull sample messages without consuming/acking them
gcloud pubsub subscriptions pull tasks-dlq-sub \
  --limit=5 \
  --auto-ack=false \
  --format="json"
```

Inspect the returned JSON payload:
- Check `message.attributes` for `cloudEvents:type`, `traceparent`, and `correlationid`.
- Decode `message.data` (Base64) to inspect the business payload.
- Correlate with worker logs using the `correlationid`:
  ```bash
  gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="template-worker" AND jsonPayload.correlation_id="<CORRELATION_ID>"' --limit=10
  ```

### 4.2 Classify Failure Type
- **Poison Pill (Bad Schema / Malformed Data)**: The message itself violates business constraints or schema contracts. Do NOT replay raw without patching the schema validator or data migration.
- **Transient Dependency Outage**: Cloud SQL was full, third-party webhook timed out, or connection limits were hit. Safe to replay once the dependency is recovered.
- **Worker Code Bug**: Edge case in worker logic. Safe to replay **after** the worker hotfix is deployed.

### 4.3 Replaying DLQ Messages to Primary Topic
Once the worker hotfix is verified and online, replay the messages from the DLQ subscription back to the primary topic (`tasks`):

#### Method A: Using gcloud & Replay Script (Targeted / Low Volume)
```bash
#!/bin/bash
set -euo pipefail

SUB="tasks-dlq-sub"
TOPIC="tasks"

echo "Reading and replaying DLQ messages to ${TOPIC}..."

while true; do
  # Pull one message at a time
  MSG=$(gcloud pubsub subscriptions pull "${SUB}" --limit=1 --auto-ack=true --format=json)
  if [ "$MSG" = "[]" ] || [ -z "$MSG" ]; then
    echo "DLQ is empty. Replay complete!"
    break
  fi

  DATA=$(echo "$MSG" | jq -r '.[0].message.data')
  ATTRIBUTES=$(echo "$MSG" | jq -r '.[0].message.attributes | to_entries | map("\(.key)=\(.value)") | join(",")')

  # Publish back to primary topic
  if [ -n "$ATTRIBUTES" ]; then
    gcloud pubsub topics publish "${TOPIC}" --message="$(echo "$DATA" | base64 -d)" --attribute="${ATTRIBUTES}"
  else
    gcloud pubsub topics publish "${TOPIC}" --message="$(echo "$DATA" | base64 -d)"
  fi

  echo "Replayed 1 message successfully."
done
```

#### Method B: Using Google Cloud Dataflow DLQ Replay Template (High Volume > 10,000 messages)
```bash
gcloud dataflow jobs run pubsub-dlq-replay \
  --gcs-location gs://dataflow-templates/latest/Cloud_PubSub_to_Cloud_PubSub \
  --region us-central1 \
  --parameters \
    inputSubscription="projects/${PROJECT_ID}/subscriptions/tasks-dlq-sub",\
    outputTopic="projects/${PROJECT_ID}/topics/tasks"
```

### 4.4 Monitor Queue Drain & Idempotency
- Cloud Pub/Sub guarantees at-least-once delivery; the worker implements idempotent deduplication via `task_id` and database unique constraints.
- Verify `tasks-dlq-sub` metric `num_undelivered_messages` reaches 0.

---

## 5. Cloud SQL Point-In-Time Recovery (PITR) SOP

Point-in-time recovery allows restoring a PostgreSQL instance to an arbitrary second in the retention window (up to 7 days) using Write-Ahead Log (WAL) archives.

### 5.1 When to Execute PITR
- Accidental table drop or truncate (`DROP TABLE tasks;`).
- Severe data corruption caused by a rogue script or compromised credentials.
- Inadvertent mass deletion without a WHERE clause.

> [!CAUTION]
> Cloud SQL PITR does NOT overwrite the existing instance directly. It provisions a **new cloned instance** at the specified point in time to preserve forensic evidence and prevent irreversible data loss.

### 5.2 Step-by-Step Restoration Procedure

#### Step 1: Identify Exact Recovery Timestamp (UTC)
Inspect Cloud Audit Logs to pinpoint the exact timestamp immediately **prior** to the corruption event:
```bash
gcloud logging read 'resource.type="cloudsql_database" AND protoPayload.methodName="cloudsql.instances.delete"' --limit=5
```
Example Target Timestamp: `2026-09-21T14:22:15Z`

#### Step 2: Clone Instance at the Target Timestamp
```bash
# Clone the production database to a restored instance at the specified second
gcloud sql instances clone template-pg-prod template-pg-pitr-recovered \
  --point-in-time="2026-09-21T14:22:15Z" \
  --async

# Monitor clone operation progress
gcloud sql operations list --instance=template-pg-prod --limit=5
```

#### Step 3: Validate Restored Database State
Once the operation completes and `template-pg-pitr-recovered` status is `RUNNABLE`:
1. Connect via Cloud SQL Auth Proxy:
   ```bash
   cloud-sql-proxy template-project:us-central1:template-pg-pitr-recovered --port=5433
   ```
2. Verify table integrity, row counts, and UUID indexes:
   ```sql
   psql -h 127.0.0.1 -p 5433 -U postgres -d app_db -c "SELECT count(*) FROM tasks;"
   psql -h 127.0.0.1 -p 5433 -U postgres -d app_db -c "SELECT count(*) FROM outbox_events;"
   ```

#### Step 4: Promote Restored Instance & Switch Service Connections
1. Update Secret Manager secret `DATABASE_URL` with the new private IP address or instance connection name:
   ```bash
   echo -n "postgres://user:pass@10.0.3.15:5432/app_db?sslmode=require" | \
     gcloud secrets versions add database-url --data-file=-
   ```
2. Redeploy or restart Cloud Run services to pick up the updated secret:
   ```bash
   gcloud run services update template-api --region=us-central1 --update-env-vars=RESTART_TIMESTAMP=$(date +%s)
   gcloud run services update template-worker --region=us-central1 --update-env-vars=RESTART_TIMESTAMP=$(date +%s)
   ```

#### Step 5: Post-Recovery Event Reconciliation
To recover events that occurred between the PITR timestamp and current time:
- Query Pub/Sub backlog or external transactional log sources.
- Re-publish any missing task events to Pub/Sub to bring background worker states up to date.

---

## 6. Post-Incident Review & Blameless Post-Mortem

Within 48 hours of resolving any P1 or P2 incident:
1. Conduct a blameless post-mortem meeting with all responders.
2. Complete the post-mortem report covering:
   - **Executive Summary & Impact**: Duration, user impact, SLO error budget consumed.
   - **Timeline**: Chronological minute-by-minute log of events, alerts, and actions.
   - **Root Cause Analysis (5 Whys)**: Underlying technical and process deficiencies.
   - **Action Items**: Preventative measures, new alerting rules, automated tests, or architectural improvements, assigned with strict Jira/GitHub issue owners and due dates.
