locals {
  tasks_topic_name       = coalesce(var.tasks_topic_name, "${var.environment}-tasks")
  task_events_topic_name = coalesce(var.task_events_topic_name, "${var.environment}-task-events")
  dead_letter_topic_name = coalesce(var.dead_letter_topic_name, "${var.environment}-dead-letter-topic")
}

data "google_project" "current" {
  project_id = var.project_id
}

# 1. Dead-Letter Topic
resource "google_pubsub_topic" "dead_letter" {
  name    = local.dead_letter_topic_name
  project = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    tier        = "dead-letter"
  }
}

# 2. Main Tasks Topic (Async Command Ingestion)
resource "google_pubsub_topic" "tasks" {
  name    = local.tasks_topic_name
  project = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    tier        = "event-backbone"
  }
}

# 3. Task Events Topic (CloudEvents State Changes)
resource "google_pubsub_topic" "task_events" {
  name    = local.task_events_topic_name
  project = var.project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    tier        = "event-backbone"
  }
}

# 4. Service Account for Authenticated Pub/Sub Push to Cloud Run
resource "google_service_account" "pubsub_invoker_sa" {
  account_id   = "${var.environment}-pubsub-invoker-sa"
  display_name = "Pub/Sub Push Invoker Service Account (${var.environment})"
  project      = var.project_id
}

# 5. Grant Pub/Sub Invoker SA the Cloud Run Invoker Role on Worker
resource "google_cloud_run_v2_service_iam_member" "worker_invoker" {
  count    = var.worker_service_name != null ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = var.worker_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker_sa.email}"
}

# 6. IAM: Allow Pub/Sub Service Agent to publish to Dead Letter Topic
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dead_letter.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# 7. Push Subscription to Worker with Dead-Letter Policy & OIDC Authentication
resource "google_pubsub_subscription" "worker_push" {
  name    = "${var.environment}-worker-tasks-sub"
  topic   = google_pubsub_topic.tasks.name
  project = var.project_id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s" # 7 days

  push_config {
    push_endpoint = var.worker_push_endpoint

    oidc_token {
      service_account_email = google_service_account.pubsub_invoker_sa.email
      audience              = var.worker_push_endpoint
    }
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  depends_on = [
    google_pubsub_topic_iam_member.dead_letter_publisher
  ]
}

# 8. Pull Subscription for Dead-Letter Queue Inspection
resource "google_pubsub_subscription" "dead_letter_pull" {
  name    = "${var.environment}-dead-letter-sub"
  topic   = google_pubsub_topic.dead_letter.name
  project = var.project_id

  ack_deadline_seconds       = 60
  message_retention_duration = "1209600s" # 14 days for forensic debugging

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 9. Pull Subscription for Task Events Topic
resource "google_pubsub_subscription" "task_events_pull" {
  name    = "${var.environment}-task-events-sub"
  topic   = google_pubsub_topic.task_events.name
  project = var.project_id

  ack_deadline_seconds       = 60
  message_retention_duration = "604800s"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
