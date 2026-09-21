output "repository_id" {
  description = "The repository ID"
  value       = google_artifact_registry_repository.repo.repository_id
}

output "repository_name" {
  description = "The fully qualified resource name of the repository"
  value       = google_artifact_registry_repository.repo.name
}

output "repository_url" {
  description = "The base URL for Docker images in this Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
