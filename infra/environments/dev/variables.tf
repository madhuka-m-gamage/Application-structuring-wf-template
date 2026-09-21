variable "project_id" {
  description = "The GCP project ID for the development environment"
  type        = string
}

variable "region" {
  description = "The GCP region for development resources"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "The GitHub repository in owner/repo format for Workload Identity Federation"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the dev application subnetwork"
  type        = string
  default     = "10.0.0.0/20"
}

variable "connector_cidr" {
  description = "CIDR block (/28) for the dev Serverless VPC Access Connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "immutable_tags" {
  description = "Enforce Docker tag immutability in Artifact Registry"
  type        = bool
  default     = true
}

# --- Cloud SQL Settings ---
variable "db_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "POSTGRES_16"
}

variable "db_tier" {
  description = "Machine type for the dev database (db-f1-micro or db-custom-1-3840)"
  type        = string
  default     = "db-custom-1-3840"
}

variable "db_availability_type" {
  description = "ZONAL for dev (cost efficiency), REGIONAL for high availability"
  type        = string
  default     = "ZONAL"
}

variable "db_disk_size" {
  description = "Initial disk size in GB for dev database"
  type        = number
  default     = 20
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery for dev database"
  type        = bool
  default     = false
}

variable "db_retained_backups" {
  description = "Number of backups retained for dev database"
  type        = number
  default     = 3
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on dev database"
  type        = bool
  default     = false
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app_db"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "app_user"
}

# --- Cloud Run Settings (Scale to Zero for Dev) ---
variable "api_image" {
  description = "Container image for API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "api_min_instances" {
  description = "Minimum instances for dev API (0 = scale-to-zero)"
  type        = number
  default     = 0
}

variable "api_max_instances" {
  description = "Maximum instances for dev API"
  type        = number
  default     = 2
}

variable "api_cpu" {
  description = "CPU allocation for dev API"
  type        = string
  default     = "1"
}

variable "api_memory" {
  description = "Memory allocation for dev API"
  type        = string
  default     = "512Mi"
}

variable "web_image" {
  description = "Container image for Web service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "web_min_instances" {
  description = "Minimum instances for dev Web (0 = scale-to-zero)"
  type        = number
  default     = 0
}

variable "web_max_instances" {
  description = "Maximum instances for dev Web"
  type        = number
  default     = 2
}

variable "web_cpu" {
  description = "CPU allocation for dev Web"
  type        = string
  default     = "1"
}

variable "web_memory" {
  description = "Memory allocation for dev Web"
  type        = string
  default     = "512Mi"
}

variable "worker_image" {
  description = "Container image for Worker service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "worker_min_instances" {
  description = "Minimum instances for dev Worker (0 = scale-to-zero)"
  type        = number
  default     = 0
}

variable "worker_max_instances" {
  description = "Maximum instances for dev Worker"
  type        = number
  default     = 2
}

variable "worker_cpu" {
  description = "CPU allocation for dev Worker"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Memory allocation for dev Worker"
  type        = string
  default     = "512Mi"
}
