# Enable Compute Engine API
resource "google_project_service" "compute_engine" {
  project = var.project_id
  service = "compute.googleapis.com"


# Create VPC
resource "google_compute_network" "my_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true
}

# Create subnets
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.webapp_subnet_name
  network       = google_compute_network.my_vpc.self_link
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = var.db_subnet_name
  network       = google_compute_network.my_vpc.self_link
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
}

resource "google_compute_global_address" "internet_gateway_ip" {
  name  = var.internet_gateway_name
}

locals {
  next_hop_ip = cidrhost(var.webapp_subnet_cidr, 1)
}


# Add route for webapp subnet
resource "google_compute_route" "webapp_route" {
  name              = var.webapp_route_name
  network           = google_compute_network.my_vpc.self_link
  dest_range        = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority = 1000
}


