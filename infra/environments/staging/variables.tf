variable "project_id" {
  description = "The GCP project ID for the staging environment"
  type        = string
}

variable "region" {
  description = "The GCP region for staging resources"
  type        = string
  default     = "us-central1"
}

variable "github_repo" {
  description = "The GitHub repository in owner/repo format for Workload Identity Federation"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the staging application subnetwork"
  type        = string
  default     = "10.10.0.0/20"
}

variable "connector_cidr" {
  description = "CIDR block (/28) for the staging Serverless VPC Access Connector"
  type        = string
  default     = "10.18.0.0/28"
}

variable "immutable_tags" {
  description = "Enforce Docker tag immutability in Artifact Registry"
  type        = bool
  default     = true
}

# --- Cloud SQL Settings (Production-Mirroring HA) ---
variable "db_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "POSTGRES_16"
}

variable "db_tier" {
  description = "Machine type for the staging database"
  type        = string
  default     = "db-custom-1-3840"
}

variable "db_availability_type" {
  description = "REGIONAL for high availability failover (mirroring production)"
  type        = string
  default     = "REGIONAL"
}

variable "db_disk_size" {
  description = "Initial disk size in GB for staging database"
  type        = number
  default     = 20
}

variable "db_pitr_enabled" {
  description = "Enable point-in-time recovery for staging database"
  type        = bool
  default     = true
}

variable "db_retained_backups" {
  description = "Number of backups retained for staging database"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on staging database"
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

# --- Cloud Run Settings (Warm instances mirroring production) ---
variable "api_image" {
  description = "Container image for API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "api_min_instances" {
  description = "Minimum instances for staging API (1 = warm)"
  type        = number
  default     = 1
}

variable "api_max_instances" {
  description = "Maximum instances for staging API"
  type        = number
  default     = 5
}

variable "api_cpu" {
  description = "CPU allocation for staging API"
  type        = string
  default     = "1"
}

variable "api_memory" {
  description = "Memory allocation for staging API"
  type        = string
  default     = "512Mi"
}

variable "web_image" {
  description = "Container image for Web service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "web_min_instances" {
  description = "Minimum instances for staging Web (1 = warm)"
  type        = number
  default     = 1
}

variable "web_max_instances" {
  description = "Maximum instances for staging Web"
  type        = number
  default     = 5
}

variable "web_cpu" {
  description = "CPU allocation for staging Web"
  type        = string
  default     = "1"
}

variable "web_memory" {
  description = "Memory allocation for staging Web"
  type        = string
  default     = "512Mi"
}

variable "worker_image" {
  description = "Container image for Worker service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "worker_min_instances" {
  description = "Minimum instances for staging Worker"
  type        = number
  default     = 1
}

variable "worker_max_instances" {
  description = "Maximum instances for staging Worker"
  type        = number
  default     = 5
}

variable "worker_cpu" {
  description = "CPU allocation for staging Worker"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Memory allocation for staging Worker"
  type        = string
  default     = "512Mi"
}
