locals {
  network_name   = coalesce(var.network_name, "${var.environment}-vpc")
  subnet_name    = "${var.environment}-subnet"
  connector_name = substr("${var.environment}-vpc-conn", 0, 25)
}

# 1. Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = local.network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.project_id
  description             = "VPC network for ${var.environment} environment"
}

# 2. Application Subnetwork with Private Google Access
resource "google_compute_subnetwork" "subnet" {
  name                     = local.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# 3. Reserved Private IP Allocation for Cloud SQL Service Networking
resource "google_compute_global_address" "sql_private_ip" {
  name          = "${var.environment}-sql-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_ip_prefix_length
  network       = google_compute_network.vpc.id
  project       = var.project_id
  description   = "Private IP range allocated for Cloud SQL peering in ${var.environment}"
}

# 4. Service Networking Connection for Private Cloud SQL Access
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.sql_private_ip.name]
  deletion_policy         = "ABANDON"
}

# 5. Serverless VPC Access Connector for Cloud Run Services
resource "google_vpc_access_connector" "connector" {
  name          = local.connector_name
  region        = var.region
  project       = var.project_id
  ip_cidr_range = var.connector_cidr
  network       = google_compute_network.vpc.name

  min_instances = var.connector_min_instances
  max_instances = var.connector_max_instances
  machine_type  = var.connector_machine_type

  depends_on = [google_compute_subnetwork.subnet]
}
