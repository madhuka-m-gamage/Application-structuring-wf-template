output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance (project:region:instance)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "The first private IPv4 address assigned to the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.db.name
}

output "database_user" {
  description = "The name of the database user"
  value       = google_sql_user.user.name
}

output "db_secret_id" {
  description = "The Secret Manager secret ID containing the connection URL"
  value       = google_secret_manager_secret.db_secret.secret_id
}

output "db_secret_name" {
  description = "The resource name of the Secret Manager secret"
  value       = google_secret_manager_secret.db_secret.name
}

output "db_secret_version_id" {
  description = "The resource name of the Secret Manager secret version"
  value       = google_secret_manager_secret_version.db_secret_version.id
}
