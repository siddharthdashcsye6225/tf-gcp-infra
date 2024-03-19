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

# Create Global Internal IP Address Block for VPC Peering 
resource "google_compute_global_address" "private_ip_block" {
  name          = var.vpc_peering_blockname
  purpose       = var.vpc_peering_purpose
  address_type  = var.vpc_peering_address_type
  ip_version    = var.vpc_peering_ip_version
  prefix_length = var.vpc_peering_prefix_length
  network       = google_compute_network.vpc_network.self_link
}

#VPC Peering 
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
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

# End of create Subnets 

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

resource "random_id" "db_name_suffix" {
  byte_length = 4
}


  resource "google_sql_database_instance" "main_primary" {
  name             = "webapp-primary-${random_id.db_name_suffix.hex}"  #Terraform will randomly generate one when the instance is first created. This is done because after a name is used, it cannot be reused for up to one week.
  database_version = var.sql_instance_database_version
  region           = var.sql_instance_database_region
  depends_on       = [google_service_networking_connection.private_vpc_connection]


  settings {
    tier              = var.sql_instance_database_tier
    availability_type = var.sql_instance_database_availability_type
    disk_size         = var.sql_instance_database_disk_size
    disk_type = var.sql_instance_database_disk_type
    
    ip_configuration {
      ipv4_enabled    = var.sql_instance_database_ip4enabled
      private_network = google_compute_network.vpc_network.self_link
      enable_private_path_for_google_cloud_services = true  
    }

    
  }
  # Add deletion_protection parameter
  deletion_protection = var.sql_instance_database_deletion_protection
}

# sql database 
  resource "google_sql_database" "main" {
    name     = "webapp"
    instance = google_sql_database_instance.main_primary.name
  }

# sql database user 
resource "google_sql_user" "cloudsql_user" {
  name     = var.database_name
  instance = google_sql_database_instance.main_primary.name
  password = random_password.cloudsql_password.result
}

# resource block for generating random password 
resource "random_password" "cloudsql_password" {
  length           = 16
  special          = true
  override_special = "#"
}

#Firewall to restrict access to db instance to just the webapp vm 
resource "google_compute_firewall" "cloudsql_access" {
  name    = var.database_firewall_name
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["5432"]  # Assuming PostgreSQL default port
  }

  source_tags = ["webapp-vm"]
    # Allow traffic from instances with this tag
}

output "cloudsql_private_ip" {
  value = google_sql_database_instance.main_primary.private_ip_address
}

# Compute Engine instance
resource "google_compute_instance" "web_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["webapp-vm"]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image  
      size  = var.boot_disk_size 
      type  = var.boot_disk_type  
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet1.self_link
    access_config {}
  }

  service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = ["cloud-platform"]  
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Replace the following placeholders with actual database configuration
    export DB_HOST="${google_sql_database_instance.main_primary.private_ip_address}"
    export DB_USER="${google_sql_user.cloudsql_user.name}"
    export DB_PASS="${google_sql_user.cloudsql_user.password}"
    export DB_NAME="${google_sql_database.main.name}"
    
    # Create a configuration file for the web application
    echo "SQLALCHEMY_DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST/$DB_NAME" > /tmp/database_url.ini
    touch /tmp/endofstartupscript.txt 
    chmod 777 /tmp/endofstartupscript.txt

    sudo systemctl daemon-reload
    sudo systemctl start webservice.service
    sudo systemctl enable webservice.service

    

  EOF
}

# Update DNS records
resource "google_dns_record_set" "webapp_dns_record" {
  managed_zone = "webapp-csye6225"
  name    = "siddharthdash.me."
  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_instance.web_instance.network_interface[0].access_config[0].nat_ip]

}

# Create Service Account
resource "google_service_account" "webapp_service_account" {
  account_id   = "webapp-service-account"
  display_name = "VM Service Account"
}

# Bind IAM roles to the Service Account
resource "google_project_iam_binding" "vm_service_account_binding" {
  project = var.project_id
  role    = "roles/logging.admin"
  
  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}

resource "google_project_iam_binding" "vm_service_account_binding_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  
  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}

