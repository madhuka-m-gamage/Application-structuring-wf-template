variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for Cloud Run services"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_connector_id" {
  description = "Serverless VPC Access Connector ID for private networking"
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress routing setting (PRIVATE_RANGES_ONLY or ALL_TRAFFIC)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}

variable "database_secret_id" {
  description = "Secret Manager secret ID containing the PostgreSQL connection URL"
  type        = string
  default     = null
}

variable "tasks_topic_name" {
  description = "Name of the Pub/Sub tasks topic"
  type        = string
  default     = "tasks"
}

variable "task_events_topic_name" {
  description = "Name of the Pub/Sub task-events topic"
  type        = string
  default     = "task-events"
}

# --- API Service Variables ---
variable "api_image" {
  description = "Container image URL for the API service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "api_cpu" {
  description = "CPU limits for the API container"
  type        = string
  default     = "1"
}

variable "api_memory" {
  description = "Memory limits for the API container"
  type        = string
  default     = "512Mi"
}

variable "api_min_instances" {
  description = "Minimum instances for the API service (0 for scale-to-zero, >=1 for warm)"
  type        = number
  default     = 0
}

variable "api_max_instances" {
  description = "Maximum instances for the API service"
  type        = number
  default     = 10
}

variable "api_ingress" {
  description = "Ingress settings for the API service (INGRESS_TRAFFIC_ALL, etc.)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "api_public_access" {
  description = "Whether the API service allows unauthenticated public access"
  type        = bool
  default     = true
}

variable "api_db_pool_max" {
  description = "Max database pool connections for the API service"
  type        = number
  default     = 10
}

# --- Web Service Variables ---
variable "web_image" {
  description = "Container image URL for the Web service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "web_port" {
  description = "Container port for the Web service"
  type        = number
  default     = 3000
}

variable "web_cpu" {
  description = "CPU limits for the Web container"
  type        = string
  default     = "1"
}

variable "web_memory" {
  description = "Memory limits for the Web container"
  type        = string
  default     = "512Mi"
}

variable "web_min_instances" {
  description = "Minimum instances for the Web service"
  type        = number
  default     = 0
}

variable "web_max_instances" {
  description = "Maximum instances for the Web service"
  type        = number
  default     = 10
}

variable "web_ingress" {
  description = "Ingress settings for the Web service"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "web_public_access" {
  description = "Whether the Web service allows unauthenticated public access"
  type        = bool
  default     = true
}

variable "web_api_url" {
  description = "The upstream API URL passed to the Web service frontend"
  type        = string
  default     = ""
}

# --- Worker Service Variables ---
variable "worker_image" {
  description = "Container image URL for the Worker service"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "worker_cpu" {
  description = "CPU limits for the Worker container"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Memory limits for the Worker container"
  type        = string
  default     = "512Mi"
}

variable "worker_min_instances" {
  description = "Minimum instances for the Worker service"
  type        = number
  default     = 0
}

variable "worker_max_instances" {
  description = "Maximum instances for the Worker service"
  type        = number
  default     = 5
}

variable "worker_ingress" {
  description = "Ingress settings for the Worker service"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "worker_db_pool_max" {
  description = "Max database pool connections for the Worker service"
  type        = number
  default     = 5
}
