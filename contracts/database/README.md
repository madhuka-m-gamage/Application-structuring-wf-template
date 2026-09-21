# Relational Database Contracts & Schema Guide

<!-- @agent-meta: {"phase": "pass-3", "artifact": "database-contracts-guide", "system": "Task Management Microservices", "version": "1.0.0", "target_db": "PostgreSQL 15/16"} -->

## 1. Overview & Architecture

This directory contains the authoritative PostgreSQL DDL schemas, visual entity-relationship models, and migration policies for the Task Management System. 

The schema is built for **Google Cloud SQL for PostgreSQL 15/16** and provides:
- **ACID relational persistence** for core domain entities (`users`, `tasks`).
- **Transactional Outbox staging** (`outbox_events`) to prevent dual-write failure between the database and Google Cloud Pub/Sub.
- **Distributed idempotency tracking** (`idempotency_keys`) to guarantee safe retries across distributed HTTP microservices and worker queues.

### File Manifest
- [`schema.sql`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/contracts/database/schema.sql): Production PostgreSQL DDL definition with extensions, custom enums, tables, indices, constraints, and audit triggers.
- [`erd.md`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/contracts/database/erd.md): Mermaid Entity-Relationship Diagram and detailed Data Dictionary with index strategies and state machine transitions.
- [`README.md`](file:///home/madhuka/VScode%20Projects/Application-structuring-wf-template/contracts/database/README.md): This operational migration and optimization guide.

---

## 2. Zero-Downtime Migration Guide: The Expand and Contract Pattern

In cloud-native, continuous deployment environments, database changes must **never break active application instances**. Traditional in-place breaking changes (`DROP COLUMN`, `RENAME COLUMN`, changing column types) cause downtime and errors during rolling deployments where multiple application versions run simultaneously.

To achieve zero downtime, all schema modifications must follow the **Expand and Contract (Parallel Run)** pattern executed across three distinct release cycles:

```mermaid
graph TD
    subgraph Phase 1: Expand
        A1[Deploy Schema Migration: Add new column/table as nullable]
        A2[Deploy App v1.1: Write to both old and new columns, read from old]
        A1 --> A2
    end

    subgraph Phase 2: Backfill
        B1[Run Background Job: Backfill legacy data into new column]
        B2[Deploy App v1.2: Read from new column, write to both]
        B1 --> B2
    end

    subgraph Phase 3: Contract
        C1[Deploy App v1.3: Cease all writes to legacy column]
        C2[Deploy Schema Migration: Drop legacy column/table]
        C1 --> C2
    end

    Phase 1 --> Phase 2 --> Phase 3
```

### Phase Breakdown

#### Phase 1: Expand (Release N)
- **Objective**: Introduce the new schema construct without affecting existing application queries.
- **Rules**:
  - New columns must be `NULLABLE` or have a safe default.
  - Do not add immediate `NOT NULL` constraints on existing tables without backfill.
  - Deploy application changes that write to both the old and new columns (dual-write), but continue reading from the old column.

#### Phase 2: Backfill (Background Maintenance)
- **Objective**: Populate the new column for historical rows created before Release N.
- **Rules**:
  - Execute backfills in small, throttled batches (e.g., 500–1000 rows per transaction) to prevent table locks and replication lag.
  - Once backfill reaches 100%, deploy the application update that begins reading from the new column.

#### Phase 3: Contract (Release N+1 or N+2)
- **Objective**: Remove the redundant old schema construct once no running application code depends on it.
- **Rules**:
  - Verify through observability metrics and logs that no legacy queries are touching the old column.
  - Remove application fallback code.
  - Drop the old column, obsolete triggers, or temporary shadow tables.

### PostgreSQL Safe Migration Rules

When writing database migration scripts (e.g., Flyway, Goose, Alembic, or golang-migrate), adhere to these mandatory PostgreSQL practices:

1. **Always Set Lock & Statement Timeouts**:
   ```sql
   -- Prevent a migration from blocking production traffic indefinitely
   SET statement_timeout = '5s';
   SET lock_timeout = '2s';
   ```
2. **Create Indices Concurrently**:
   ```sql
   -- NEVER run standard CREATE INDEX in production (locks table against writes)
   -- ALWAYS use CONCURRENTLY:
   CREATE INDEX CONCURRENTLY idx_tasks_user_status ON tasks (user_id, status);
   ```
3. **Adding `NOT NULL` Columns Safely**:
   - In PostgreSQL 11+, `ALTER TABLE tasks ADD COLUMN flag BOOLEAN DEFAULT false NOT NULL;` is fast (metadata-only update).
   - If using complex or non-constant defaults, add the column as nullable first, backfill rows in batches, add a `CHECK (flag IS NOT NULL) NOT VALID`, validate it with `VALIDATE CONSTRAINT`, and then set `ALTER COLUMN flag SET NOT NULL`.
4. **Renaming Columns**:
   - Never rename a column directly (`ALTER TABLE tasks RENAME COLUMN a TO b`). This immediately breaks existing running replicas.
   - Use the Expand and Contract pattern with dual-writing or views instead.

---

## 3. Guidelines for AI Coding Agents & Developers

### 3.1 Query Optimization Rules

1. **Avoid the N+1 Query Problem**:
   - When retrieving tasks along with user profiles, never query the user table inside a loop.
   - Use SQL joins or array batching:
     ```sql
     -- GOOD: Single batch query using ANY/IN
     SELECT id, email, name FROM users WHERE id = ANY($1::uuid[]);
     ```
2. **Keyset (Cursor) Pagination over `OFFSET`**:
   - `LIMIT 20 OFFSET 50000` requires PostgreSQL to scan and discard 50,000 rows, creating high I/O spikes.
   - Always use keyset pagination with indexed columns:
     ```sql
     -- GOOD: Sub-millisecond pagination at any depth
     SELECT id, title, status, created_at 
     FROM tasks 
     WHERE user_id = $1 
       AND created_at < $cursor_timestamp 
     ORDER BY created_at DESC 
     LIMIT $page_size;
     ```
3. **JSONB Indexing Best Practices**:
   - Queries inspecting specific JSONB paths in `tasks.payload` must use targeted GIN or expression indices:
     ```sql
     -- Expression index on specific JSONB field:
     CREATE INDEX idx_tasks_payload_action 
     ON tasks ((payload->>'action_type'));
     ```
4. **Verify Query Plans**:
   - Test non-trivial queries with `EXPLAIN (ANALYZE, BUFFERS)` to ensure that index scans (`Index Scan` or `Bitmap Index Scan`) are executed rather than sequential scans (`Seq Scan`).

### 3.2 Connection Pooling & Resource Limits

1. **Connection Budgeting**:
   - Direct connections to PostgreSQL consume approximately 10MB of RAM per backend process.
   - Sizing formula for Cloud SQL / PostgreSQL instances:
     $$\text{max\_pool\_size} = (\text{CPU Cores} \times 2) + \text{Effective Spindles}$$
   - For Cloud Run serverless deployments that scale horizontally up to hundreds of container instances, **direct database connections are strictly prohibited**. All microservices must route connections through a connection pooler (e.g. **PgBouncer** in transaction pooling mode) or the **Cloud SQL Auth Proxy**.
2. **Client Pool Configuration**:
   - Set maximum open connections per container instance between 5 and 10.
   - Set connection max lifetime (`max_conn_lifetime`) to 30 minutes to recycle connections cleanly.
   - Set connection idle timeout (`max_idle_time`) to 5 minutes.
3. **Transient Network Resilience**:
   - Applications must implement exponential backoff with jitter when encountering transient connection resets (`SQLSTATE 08006`, `57P01`).
   - Transactions must be bounded with query timeouts (`statement_timeout`) to protect connection pool slots.

### 3.3 Transaction Boundaries & Concurrency

1. **Keep Transactions Short**:
   - Never perform HTTP network requests, third-party API calls, or lengthy CPU hashing inside an open SQL transaction.
   - Acquire locks as late as possible and commit immediately.
2. **Outbox Polling Concurrency**:
   - Background event dispatchers polling `outbox_events` must use `FOR UPDATE SKIP LOCKED` to allow multiple concurrent relay workers to poll without deadlocks:
     ```sql
     SELECT id, aggregate_id, event_type, payload
     FROM outbox_events
     WHERE status = 'PENDING'
     ORDER BY created_at ASC
     LIMIT 100
     FOR UPDATE SKIP LOCKED;
     ```
3. **Row-Level Locking**:
   - If task processing status needs pessimistic locking, use `SELECT ... FOR UPDATE` with a 3-second statement timeout to avoid cascading queue locks.

---

## 4. Security & Compliance Controls

- **Principle of Least Privilege**:
  - The runtime application service account (`app_user`) is granted only `DML` rights (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) on tables and sequences.
  - `DDL` permissions (`CREATE`, `ALTER`, `DROP`) are strictly reserved for automated CI/CD migration runners executing under a dedicated `migration_user`.
- **Prepared Statements**:
  - Every SQL query generated by developers or AI agents must use parameterized placeholders (`$1, $2, ...` in PostgreSQL or `?` in prepared abstractions) to prevent SQL injection vulnerabilities.
- **PII & Data Retention**:
  - The `users.email` and `users.name` columns constitute personally identifiable information (PII). Any database backups, replicas, or telemetry loggers must mask or redact these columns.
