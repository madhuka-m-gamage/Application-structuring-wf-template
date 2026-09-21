locals {
  instance_name = coalesce(var.instance_name, "${var.environment}-pg-${random_id.instance_suffix.hex}")
}

resource "random_id" "instance_suffix" {
  byte_length = 3
}

resource "random_password" "db_password" {
  length  = 24
  special = false
}

# 1. Cloud SQL for PostgreSQL Instance (Private IP Only)
resource "google_sql_database_instance" "postgres" {
  name                = local.instance_name
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
      ssl_mode        = "ENCRYPTED_ONLY"
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.pitr_enabled
      start_time                     = "03:00"
      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day          = 7
      hour         = 4
      update_track = "stable"
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    user_labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}

# 2. Application Database
resource "google_sql_database" "db" {
  name     = var.database_name
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# 3. Application Database User
resource "google_sql_user" "user" {
  name     = var.database_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
  project  = var.project_id
}

# 4. Secret Manager Secret for Connection String
resource "google_secret_manager_secret" "db_secret" {
  secret_id = "${var.environment}-database-url"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# 5. Secret Manager Version with PostgreSQL Connection URL
resource "google_secret_manager_secret_version" "db_secret_version" {
  secret      = google_secret_manager_secret.db_secret.id
  secret_data = "postgres://${google_sql_user.user.name}:${random_password.db_password.result}@${google_sql_database_instance.postgres.private_ip_address}:5432/${google_sql_database.db.name}?sslmode=require"
}
