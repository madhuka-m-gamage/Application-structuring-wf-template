variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud SQL instance"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "network_id" {
  description = "The VPC network ID or self-link for private IP connectivity"
  type        = string
}

variable "vpc_connection_id" {
  description = "The ID of the private service networking connection (used as explicit dependency)"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Custom instance name. If omitted, a name with random suffix is generated"
  type        = string
  default     = null
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier for the database instance (e.g. db-f1-micro, db-custom-1-3840)"
  type        = string
  default     = "db-custom-1-3840"
}

variable "availability_type" {
  description = "Availability type: ZONAL (single zone) or REGIONAL (high availability failover)"
  type        = string
  default     = "ZONAL"
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type: PD_SSD or PD_HDD"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Enable automatic storage increases"
  type        = bool
  default     = true
}

variable "pitr_enabled" {
  description = "Enable point-in-time recovery (binary logging/WAL)"
  type        = bool
  default     = false
}

variable "retained_backups" {
  description = "Number of automated daily backups to retain"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the database instance"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "The name of the initial database to create"
  type        = string
  default     = "app_db"
}

variable "database_user" {
  description = "The username for the primary database user"
  type        = string
  default     = "app_user"
}
