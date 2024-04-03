output "vpc_id" {
  value = google_compute_network.webapp_vpc_network.id
}

output "webapp_subnet_id" {
  value = google_compute_subnetwork.webapp_subnet1.id
}

output "db_subnet_id" {
  value = google_compute_subnetwork.db_subnet1.id
}
