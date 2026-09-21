output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The URI of the created VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_id" {
  description = "The ID of the application subnetwork"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "The name of the application subnetwork"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr" {
  description = "The CIDR range of the application subnetwork"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "connector_id" {
  description = "The ID of the Serverless VPC Access Connector"
  value       = google_vpc_access_connector.connector.id
}

output "connector_name" {
  description = "The name of the Serverless VPC Access Connector"
  value       = google_vpc_access_connector.connector.name
}

output "private_vpc_connection_id" {
  description = "The ID of the private service networking connection"
  value       = google_service_networking_connection.private_vpc_connection.id
}
