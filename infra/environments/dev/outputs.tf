# --- Networking ---
output "vpc_network_name" {
  description = "Name of the VPC network"
  value       = module.vpc.network_name
}

output "vpc_connector_name" {
  description = "Name of the Serverless VPC Access Connector"
  value       = module.vpc.connector_name
}

# --- Artifact Registry ---
output "artifact_registry_url" {
  description = "Base URL for Artifact Registry Docker images"
  value       = module.artifact_registry.repository_url
}

# --- CI/CD & WIF ---
output "workload_identity_provider" {
  description = "Full provider path for GitHub Actions OIDC"
  value       = module.iam_wif.workload_identity_provider_name
}

output "cicd_service_account_email" {
  description = "Email of the CI/CD service account"
  value       = module.iam_wif.service_account_email
}

# --- Cloud SQL ---
output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloud_sql.instance_name
}

output "database_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = module.cloud_sql.private_ip_address
}

output "database_secret_id" {
  description = "Secret Manager secret ID containing connection URL"
  value       = module.cloud_sql.db_secret_id
}

# --- Cloud Run Services ---
output "web_service_url" {
  description = "Public URL for the Web UI"
  value       = module.cloud_run.web_uri
}

output "api_service_url" {
  description = "Public URL for the REST API"
  value       = module.cloud_run.api_uri
}

output "worker_service_url" {
  description = "Private URL for the Background Worker"
  value       = module.cloud_run.worker_uri
}

# --- Pub/Sub ---
output "tasks_topic_id" {
  description = "ID of the tasks topic"
  value       = module.pubsub.tasks_topic_id
}

output "task_events_topic_id" {
  description = "ID of the task-events topic"
  value       = module.pubsub.task_events_topic_id
}

output "dead_letter_topic_id" {
  description = "ID of the dead-letter topic"
  value       = module.pubsub.dead_letter_topic_id
}
