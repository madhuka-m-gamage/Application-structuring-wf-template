variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the Artifact Registry repository"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "repository_id" {
  description = "The repository ID. If omitted, defaults to <environment>-docker-repo"
  type        = string
  default     = null
}

variable "immutable_tags" {
  description = "Whether tag immutability is enforced for Docker images"
  type        = bool
  default     = true
}

variable "description" {
  description = "Custom description for the repository"
  type        = string
  default     = null
}
