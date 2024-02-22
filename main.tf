# Enable Compute Engine API
resource "google_project_service" "compute_engine" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# Create VPC
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode_vpc
  delete_default_routes_on_create = true
}

# Create subnets
resource "google_compute_subnetwork" "webapp_subnet1" {
  name          = var.webapp_subnet_name
  network       = google_compute_network.vpc_network.self_link
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "db_subnet1" {
  name          = var.db_subnet_name
  network       = google_compute_network.vpc_network.self_link
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
resource "google_compute_route" "route_for_webapp" {
  name              = var.webapp_route_name
  network           = google_compute_network.vpc_network.self_link
  dest_range        = var.route_dest_range
  next_hop_gateway = var.next_hop_gateway
  priority = 1000
}

# Firewall rule to allow traffic to application port
resource "google_compute_firewall" "webapp_firewall" {
  name    = var.allow_rule_name
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }

  # Restrict access to specific IPs if needed
  source_ranges = var.allowed_ips
  target_tags = ["webapp-vm"]  # Use a list of allowed IP addresses or ranges
}

# Firewall rule to deny SSH traffic
resource "google_compute_firewall" "deny_ssh_firewall" {
  name    = "deny-ssh-traffic"
  network = google_compute_network.vpc_network.self_link

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Restrict access to specific IPs if needed
  source_ranges = var.allowed_ips
  target_tags = ["webapp-vm"]  # Use a list of allowed IP addresses or ranges
}

# Compute Engine instance
resource "google_compute_instance" "web_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags = ["webapp-vm"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image  
      size  = var.boot_disk_size  
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet1.self_link
    access_config {
      
    }
  }
}

#boot disk type in gce 
#target tags in allow and deny should be instance tag 
#network tier 