# --- API Outputs ---
output "api_name" {
  description = "Name of the API Cloud Run service"
  value       = google_cloud_run_v2_service.api.name
}

output "api_uri" {
  description = "The main URI at which the API service is reachable"
  value       = google_cloud_run_v2_service.api.uri
}

output "api_service_account_email" {
  description = "Email of the API service account"
  value       = google_service_account.api_sa.email
}

# --- Web Outputs ---
output "web_name" {
  description = "Name of the Web Cloud Run service"
  value       = google_cloud_run_v2_service.web.name
}

output "web_uri" {
  description = "The main URI at which the Web service is reachable"
  value       = google_cloud_run_v2_service.web.uri
}

output "web_service_account_email" {
  description = "Email of the Web service account"
  value       = google_service_account.web_sa.email
}

# --- Worker Outputs ---
output "worker_name" {
  description = "Name of the Worker Cloud Run service"
  value       = google_cloud_run_v2_service.worker.name
}

output "worker_uri" {
  description = "The main URI at which the Worker service is reachable"
  value       = google_cloud_run_v2_service.worker.uri
}

output "worker_service_account_email" {
  description = "Email of the Worker service account"
  value       = google_service_account.worker_sa.email
}
