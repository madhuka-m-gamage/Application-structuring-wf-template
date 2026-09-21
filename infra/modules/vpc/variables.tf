variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the VPC and subnet"
  type        = string
}

variable "environment" {
  description = "The deployment environment (dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network. If omitted, defaults to <environment>-vpc"
  type        = string
  default     = null
}

variable "subnet_cidr" {
  description = "CIDR range for the primary application subnetwork"
  type        = string
  default     = "10.0.0.0/20"
}

variable "connector_cidr" {
  description = "CIDR range (/28) for the Serverless VPC Access Connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "private_ip_prefix_length" {
  description = "Prefix length for the internal Cloud SQL private service access range"
  type        = number
  default     = 16
}

variable "connector_min_instances" {
  description = "Minimum number of throughput instances for the Serverless VPC Access Connector"
  type        = number
  default     = 2
}

variable "connector_max_instances" {
  description = "Maximum number of throughput instances for the Serverless VPC Access Connector"
  type        = number
  default     = 3
}

variable "connector_machine_type" {
  description = "Machine type for the Serverless VPC Access Connector"
  type        = string
  default     = "e2-micro"
}
