-- ============================================================================
-- Production PostgreSQL 15/16 DDL Schema
-- System Design-to-Deployment Workflow Template
-- Component: Relational Persistence Layer (Cloud SQL / PostgreSQL)
-- ============================================================================
-- Description:
--   Complete production DDL schema defining domain entities, relational
--   constraints, transactional outbox pattern, distributed idempotency tracking,
--   optimized B-tree / partial indices, and automated audit triggers.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Database Extensions
-- ----------------------------------------------------------------------------
-- uuid-ossp: Provides functions to generate UUIDs based on standard algorithms.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- pgcrypto: Provides cryptographic functions including gen_random_uuid().
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------------------------
-- 2. Custom Enumerations
-- ----------------------------------------------------------------------------
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status_enum') THEN
        CREATE TYPE task_status_enum AS ENUM (
            'PENDING',
            'QUEUED',
            'PROCESSING',
            'COMPLETED',
            'FAILED',
            'CANCELLED'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_priority_enum') THEN
        CREATE TYPE task_priority_enum AS ENUM (
            'LOW',
            'MEDIUM',
            'HIGH',
            'CRITICAL'
        );
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 3. Utility Functions & Audit Triggers
-- ----------------------------------------------------------------------------
-- Function: update_updated_at_column()
-- Automatically updates updated_at timestamp on row modification.
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 4. Table: users
-- Core account and identity records within the tenant.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Table Constraints
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_users_name_not_empty CHECK (char_length(trim(name)) > 0),
    CONSTRAINT chk_users_role CHECK (role IN ('user', 'admin', 'operator', 'system'))
);

COMMENT ON TABLE users IS 'Registered users and security principals authorized to submit and manage tasks.';
COMMENT ON COLUMN users.id IS 'RFC 4122 compliant UUID v4 surrogate primary key.';
COMMENT ON COLUMN users.email IS 'Unique, normalized email address used as login identity.';
COMMENT ON COLUMN users.name IS 'Display name of user or service principal.';
COMMENT ON COLUMN users.role IS 'Role-based access control designation (user, admin, operator, system).';
COMMENT ON COLUMN users.created_at IS 'UTC timestamp when user account was provisioned.';
COMMENT ON COLUMN users.updated_at IS 'UTC timestamp when user record was last modified.';

-- Trigger: users.updated_at
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- 5. Table: tasks
-- Primary domain entity tracking compute workloads and asynchronous jobs.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status task_status_enum NOT NULL DEFAULT 'PENDING',
    priority task_priority_enum NOT NULL DEFAULT 'MEDIUM',
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    result JSONB,
    retry_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,

    -- Foreign Key Constraints
    CONSTRAINT fk_tasks_user_id FOREIGN KEY (user_id)
        REFERENCES users (id)
        ON DELETE CASCADE
        ON UPDATE RESTRICT,

    -- Check Constraints
    CONSTRAINT chk_tasks_title_not_empty CHECK (char_length(trim(title)) > 0),
    CONSTRAINT chk_tasks_retry_count_positive CHECK (retry_count >= 0),
    CONSTRAINT chk_tasks_completed_after_created CHECK (
        completed_at IS NULL OR completed_at >= created_at
    ),
    CONSTRAINT chk_tasks_terminal_completed_at CHECK (
        (status IN ('COMPLETED', 'FAILED', 'CANCELLED') AND completed_at IS NOT NULL) OR
        (status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED'))
    )
);

COMMENT ON TABLE tasks IS 'Unit of asynchronous work submitted by users and processed by worker services.';
COMMENT ON COLUMN tasks.id IS 'RFC 4122 compliant UUID v4 unique identifier.';
COMMENT ON COLUMN tasks.user_id IS 'Foreign key referencing owning user in users table.';
COMMENT ON COLUMN tasks.title IS 'Short human-readable summary of the task.';
COMMENT ON COLUMN tasks.description IS 'Detailed specification or context for the requested workload.';
COMMENT ON COLUMN tasks.status IS 'Current lifecycle state of the task (PENDING, QUEUED, PROCESSING, COMPLETED, FAILED, CANCELLED).';
COMMENT ON COLUMN tasks.priority IS 'Scheduling priority level (LOW, MEDIUM, HIGH, CRITICAL).';
COMMENT ON COLUMN tasks.payload IS 'Arbitrary structured JSON input data consumed by the background worker.';
COMMENT ON COLUMN tasks.result IS 'Structured JSON output, return values, or error details produced upon task execution.';
COMMENT ON COLUMN tasks.retry_count IS 'Number of retry attempts executed following transient task execution failures.';
COMMENT ON COLUMN tasks.created_at IS 'UTC timestamp when task was created.';
COMMENT ON COLUMN tasks.updated_at IS 'UTC timestamp when task was last modified.';
COMMENT ON COLUMN tasks.completed_at IS 'UTC timestamp when task reached terminal state (COMPLETED, FAILED, CANCELLED).';

-- Trigger: tasks.updated_at
DROP TRIGGER IF EXISTS trg_tasks_updated_at ON tasks;
CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- 6. Table: outbox_events
-- Transactional Outbox pattern ensuring reliable at-least-once message dispatch
-- to Cloud Pub/Sub without dual-write race conditions.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS outbox_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMPTZ,

    -- Check Constraints
    CONSTRAINT chk_outbox_events_status CHECK (
        status IN ('PENDING', 'PROCESSING', 'PUBLISHED', 'FAILED')
    ),
    CONSTRAINT chk_outbox_events_published_after_created CHECK (
        published_at IS NULL OR published_at >= created_at
    )
);

COMMENT ON TABLE outbox_events IS 'Transactional outbox table staging domain events atomically with business transactions.';
COMMENT ON COLUMN outbox_events.id IS 'Unique identifier for the outbox event record.';
COMMENT ON COLUMN outbox_events.aggregate_type IS 'Domain aggregate emitting the event (e.g., "task", "user").';
COMMENT ON COLUMN outbox_events.aggregate_id IS 'Identifier of the specific domain aggregate entity instance.';
COMMENT ON COLUMN outbox_events.event_type IS 'Fully-qualified event type name (e.g., "task.created.v1", "task.completed.v1").';
COMMENT ON COLUMN outbox_events.payload IS 'CloudEvents-compliant event body serialized as JSONB.';
COMMENT ON COLUMN outbox_events.status IS 'Dispatch lifecycle state (PENDING, PROCESSING, PUBLISHED, FAILED).';
COMMENT ON COLUMN outbox_events.created_at IS 'UTC timestamp when event was staged in database transaction.';
COMMENT ON COLUMN outbox_events.published_at IS 'UTC timestamp when event was confirmed published to Cloud Pub/Sub.';

-- ----------------------------------------------------------------------------
-- 7. Table: idempotency_keys
-- Distributed deduplication cache preventing duplicate mutations from API retries.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS idempotency_keys (
    key VARCHAR(255) PRIMARY KEY,
    request_hash VARCHAR(64) NOT NULL,
    response_code INT,
    response_body JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,

    -- Check Constraints
    CONSTRAINT chk_idempotency_expires_after_created CHECK (expires_at > created_at),
    CONSTRAINT chk_idempotency_response_code_range CHECK (
        response_code IS NULL OR (response_code >= 100 AND response_code <= 599)
    )
);

COMMENT ON TABLE idempotency_keys IS 'Idempotency registry ensuring safe retries of non-idempotent HTTP POST/PATCH requests.';
COMMENT ON COLUMN idempotency_keys.key IS 'Unique client-provided idempotency key (e.g. Idempotency-Key HTTP header).';
COMMENT ON COLUMN idempotency_keys.request_hash IS 'SHA-256 hash of incoming request path, headers, and payload to detect payload mismatch.';
COMMENT ON COLUMN idempotency_keys.response_code IS 'HTTP status code cached from first successful execution.';
COMMENT ON COLUMN idempotency_keys.response_body IS 'Cached HTTP response payload returned directly on replay.';
COMMENT ON COLUMN idempotency_keys.created_at IS 'UTC timestamp when idempotency lock was initialized.';
COMMENT ON COLUMN idempotency_keys.expires_at IS 'TTL expiration timestamp after which the idempotency key is purged or reclaimed.';

-- ----------------------------------------------------------------------------
-- 8. Indices for High-Throughput Workloads
-- ----------------------------------------------------------------------------

-- Users Indices
CREATE INDEX IF NOT EXISTS idx_users_created_at 
    ON users (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_role 
    ON users (role);

-- Tasks Indices
-- 1. B-tree index on foreign key user_id (supports joins and per-user filtering)
CREATE INDEX IF NOT EXISTS idx_tasks_user_id 
    ON tasks (user_id);

-- 2. B-tree index on status (supports status-based dashboard filtering and polling)
CREATE INDEX IF NOT EXISTS idx_tasks_status 
    ON tasks (status);

-- 3. B-tree index on priority (supports priority queue ordering)
CREATE INDEX IF NOT EXISTS idx_tasks_priority 
    ON tasks (priority);

-- 4. B-tree index on created_at (supports cursor/keyset pagination)
CREATE INDEX IF NOT EXISTS idx_tasks_created_at 
    ON tasks (created_at DESC);

-- 5. Composite index for user task list sorted by creation time
CREATE INDEX IF NOT EXISTS idx_tasks_user_id_created_at 
    ON tasks (user_id, created_at DESC);

-- 6. Composite index for user task filtering by status
CREATE INDEX IF NOT EXISTS idx_tasks_user_id_status 
    ON tasks (user_id, status);

-- Outbox Events Indices
-- 1. B-tree index on status
CREATE INDEX IF NOT EXISTS idx_outbox_events_status 
    ON outbox_events (status);

-- 2. B-tree index on created_at
CREATE INDEX IF NOT EXISTS idx_outbox_events_created_at 
    ON outbox_events (created_at DESC);

-- 3. Composite index on aggregate lookups
CREATE INDEX IF NOT EXISTS idx_outbox_events_aggregate 
    ON outbox_events (aggregate_type, aggregate_id);

-- 4. CRITICAL: Partial index for high-throughput outbox publisher polling
-- Only indexes rows needing publication; remains ultra-compact even as outbox grows.
CREATE INDEX IF NOT EXISTS idx_outbox_events_pending 
    ON outbox_events (created_at ASC) 
    WHERE status = 'PENDING';

-- Idempotency Keys Indices
-- Index on expires_at for efficient TTL expiration sweeps and vacuum cleanup
CREATE INDEX IF NOT EXISTS idx_idempotency_keys_expires_at 
    ON idempotency_keys (expires_at ASC);
