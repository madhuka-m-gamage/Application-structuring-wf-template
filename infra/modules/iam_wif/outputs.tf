output "workload_identity_pool_id" {
  description = "The Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.pool.workload_identity_pool_id
}

output "workload_identity_pool_name" {
  description = "The Workload Identity Pool resource name"
  value       = google_iam_workload_identity_pool.pool.name
}

output "workload_identity_provider_name" {
  description = "The full provider resource name for GitHub Actions auth (projects/PROJECT_NUM/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID)"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "service_account_email" {
  description = "The email of the CI/CD service account"
  value       = google_service_account.cicd_sa.email
}

output "service_account_name" {
  description = "The resource name of the CI/CD service account"
  value       = google_service_account.cicd_sa.name
}
