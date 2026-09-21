locals {
  repository_id = coalesce(var.repository_id, "${var.environment}-docker-repo")
  description   = coalesce(var.description, "Docker repository for ${var.environment} container images with immutable tags")
}

# Google Artifact Registry Docker Repository with Tag Immutability
resource "google_artifact_registry_repository" "repo" {
  repository_id = local.repository_id
  location      = var.region
  format        = "DOCKER"
  project       = var.project_id
  description   = local.description

  docker_config {
    immutable_tags = var.immutable_tags
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}
