variable "project_id" {
  description = "The GCP project ID for the production environment"
  type        = string
}

variable "region" {
  description = "The GCP region for production resources"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "The GitHub repository in owner/repo format for Workload Identity Federation"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the production application subnetwork"
  type        = string
  default     = "10.20.0.0/20"
}

variable "connector_cidr" {
  description = "CIDR block (/28) for the production Serverless VPC Access Connector"
  type        = string
  default     = "10.28.0.0/28"
}

variable "immutable_tags" {
  description = "Enforce Docker tag immutability in Artifact Registry"
  type        = bool
  default     = true
}

# --- Cloud SQL Settings (Production High Availability) ---
variable "db_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "POSTGRES_16"
}

variable "db_tier" {
  description = "Machine type for the production database (e.g. db-custom-2-7680)"
  type        = string
  default     = "db-custom-2-7680"
}

variable "db_availability_type" {
  description = "REGIONAL for high availability failover across multiple zones"
  type        = string
  default     = "REGIONAL"
}

variable "db_disk_size" {
  description = "Initial disk size in GB for production database"
  type        = number
  default     = 50
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery for production database"
  type        = bool
  default     = true
}

variable "db_retained_backups" {
  description = "Number of daily backups retained for production database"
  type        = number
  default     = 30
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on production database"
  type        = bool
  default     = true
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

# --- Cloud Run Settings (Warm instances: min_instances >= 1, scale up to 20) ---
variable "api_image" {
  description = "Container image for API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "api_min_instances" {
  description = "Minimum instances for production API (>=1 to eliminate cold starts)"
  type        = number
  default     = 1
}

variable "api_max_instances" {
  description = "Maximum instances for production API"
  type        = number
  default     = 20
}

variable "api_cpu" {
  description = "CPU allocation for production API"
  type        = string
  default     = "2"
}

variable "api_memory" {
  description = "Memory allocation for production API"
  type        = string
  default     = "1Gi"
}

variable "web_image" {
  description = "Container image for Web service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "web_min_instances" {
  description = "Minimum instances for production Web (>=1 to eliminate cold starts)"
  type        = number
  default     = 1
}

variable "web_max_instances" {
  description = "Maximum instances for production Web"
  type        = number
  default     = 20
}

variable "web_cpu" {
  description = "CPU allocation for production Web"
  type        = string
  default     = "1"
}

variable "web_memory" {
  description = "Memory allocation for production Web"
  type        = string
  default     = "1Gi"
}

variable "worker_image" {
  description = "Container image for Worker service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "worker_min_instances" {
  description = "Minimum instances for production Worker (>=1 for immediate event consumption)"
  type        = number
  default     = 1
}

variable "worker_max_instances" {
  description = "Maximum instances for production Worker"
  type        = number
  default     = 10
}

variable "worker_cpu" {
  description = "CPU allocation for production Worker"
  type        = string
  default     = "2"
}

variable "worker_memory" {
  description = "Memory allocation for production Worker"
  type        = string
  default     = "1Gi"
}
