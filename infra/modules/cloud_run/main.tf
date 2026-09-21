# ==============================================================================
# Service Accounts for Cloud Run Runtimes
# ==============================================================================

resource "google_service_account" "api_sa" {
  account_id   = "${var.environment}-api-sa"
  display_name = "Cloud Run API Service Account (${var.environment})"
  project      = var.project_id
}

resource "google_service_account" "web_sa" {
  account_id   = "${var.environment}-web-sa"
  display_name = "Cloud Run Web Service Account (${var.environment})"
  project      = var.project_id
}

resource "google_service_account" "worker_sa" {
  account_id   = "${var.environment}-worker-sa"
  display_name = "Cloud Run Worker Service Account (${var.environment})"
  project      = var.project_id
}

# ==============================================================================
# IAM Permissions for Database Secrets & Pub/Sub
# ==============================================================================

resource "google_secret_manager_secret_iam_member" "api_db_secret" {
  count     = var.database_secret_id != null ? 1 : 0
  secret_id = var.database_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.api_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "worker_db_secret" {
  count     = var.database_secret_id != null ? 1 : 0
  secret_id = var.database_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.worker_sa.email}"
}

resource "google_project_iam_member" "api_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

resource "google_project_iam_member" "worker_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.worker_sa.email}"
}

# ==============================================================================
# 1. API Service (REST API Gateway & Domain Core)
# ==============================================================================

resource "google_cloud_run_v2_service" "api" {
  name     = "${var.environment}-api"
  location = var.region
  project  = var.project_id
  ingress  = var.api_ingress

  template {
    service_account = google_service_account.api_sa.email

    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = var.api_max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = var.vpc_egress
      }
    }

    containers {
      image = var.api_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.api_cpu
          memory = var.api_memory
        }
      }

      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      env {
        name  = "DB_POOL_MAX"
        value = tostring(var.api_db_pool_max)
      }
      env {
        name  = "PUBSUB_PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "PUBSUB_TOPIC_TASKS"
        value = var.tasks_topic_name
      }
      env {
        name  = "PUBSUB_TOPIC_TASK_EVENTS"
        value = var.task_events_topic_name
      }

      dynamic "env" {
        for_each = var.database_secret_id != null ? [1] : []
        content {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = var.database_secret_id
              version = "latest"
            }
          }
        }
      }

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = 8080
        }
      }

      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 15
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = 8080
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_iam_member.api_db_secret,
    google_project_iam_member.api_pubsub_publisher
  ]
}

resource "google_cloud_run_v2_service_iam_member" "api_public" {
  count    = var.api_public_access ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ==============================================================================
# 2. Web Service (Frontend SPA / UI Dashboard)
# ==============================================================================

resource "google_cloud_run_v2_service" "web" {
  name     = "${var.environment}-web"
  location = var.region
  project  = var.project_id
  ingress  = var.web_ingress

  template {
    service_account = google_service_account.web_sa.email

    scaling {
      min_instance_count = var.web_min_instances
      max_instance_count = var.web_max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = var.vpc_egress
      }
    }

    containers {
      image = var.web_image

      ports {
        container_port = var.web_port
      }

      resources {
        limits = {
          cpu    = var.web_cpu
          memory = var.web_memory
        }
      }

      env {
        name  = "PORT"
        value = tostring(var.web_port)
      }
      env {
        name  = "HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      env {
        name  = "API_URL"
        value = var.web_api_url != "" ? var.web_api_url : google_cloud_run_v2_service.api.uri
      }

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = var.web_port
        }
      }

      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 15
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = var.web_port
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "web_public" {
  count    = var.web_public_access ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.web.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ==============================================================================
# 3. Worker Service (Background Event Processor)
# ==============================================================================

resource "google_cloud_run_v2_service" "worker" {
  name     = "${var.environment}-worker"
  location = var.region
  project  = var.project_id
  ingress  = var.worker_ingress

  template {
    service_account = google_service_account.worker_sa.email

    scaling {
      min_instance_count = var.worker_min_instances
      max_instance_count = var.worker_max_instances
    }

    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = var.vpc_egress
      }
    }

    containers {
      image = var.worker_image

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = var.worker_cpu
          memory = var.worker_memory
        }
      }

      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      env {
        name  = "DB_POOL_MAX"
        value = tostring(var.worker_db_pool_max)
      }
      env {
        name  = "PUBSUB_PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "PUBSUB_TOPIC_TASK_EVENTS"
        value = var.task_events_topic_name
      }

      dynamic "env" {
        for_each = var.database_secret_id != null ? [1] : []
        content {
          name = "DATABASE_URL"
          value_source {
            secret_key_ref {
              secret  = var.database_secret_id
              version = "latest"
            }
          }
        }
      }

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 3
        period_seconds        = 10
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = 8080
        }
      }

      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 3
        period_seconds        = 15
        failure_threshold     = 3
        http_get {
          path = "/healthz"
          port = 8080
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [
    google_secret_manager_secret_iam_member.worker_db_secret,
    google_project_iam_member.worker_pubsub_publisher
  ]
}
