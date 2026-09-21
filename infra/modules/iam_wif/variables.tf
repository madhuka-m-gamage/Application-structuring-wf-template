variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository in the format owner/repo (e.g. 'octocat/hello-world')"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID. If omitted, defaults to <environment>-github-pool"
  type        = string
  default     = null
}

variable "provider_id" {
  description = "Workload Identity Pool Provider ID"
  type        = string
  default     = "github-provider"
}

variable "service_account_id" {
  description = "Account ID for the CI/CD Service Account. If omitted, defaults to <environment>-cicd-sa"
  type        = string
  default     = null
}

variable "cicd_roles" {
  description = "IAM roles granted to the CI/CD service account for automated deployments"
  type        = list(string)
  default = [
    "roles/run.admin",
    "roles/artifactregistry.writer",
    "roles/iam.serviceAccountUser"
  ]
}
