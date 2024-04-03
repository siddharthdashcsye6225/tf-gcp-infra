# Enable Compute Engine API
resource "google_project_service" "compute_engine" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# Create VPC
resource "google_compute_network" "webapp_vpc_network" {
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
  network       = google_compute_network.webapp_vpc_network.self_link
}

#VPC Peering 
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.webapp_vpc_network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_block.name]
}


# Create subnets
resource "google_compute_subnetwork" "webapp_subnet1" {
  name          = var.webapp_subnet_name
  network       = google_compute_network.webapp_vpc_network.self_link
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "db_subnet1" {
  name          = var.db_subnet_name
  network       = google_compute_network.webapp_vpc_network.self_link
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
  network           = google_compute_network.webapp_vpc_network.self_link
  dest_range        = var.route_dest_range
  next_hop_gateway = var.next_hop_gateway
  priority = 1000
}

#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_template
# check out section "Using with Instance Group Manager" for future reference
resource "google_compute_region_instance_template" "webapp_instance_template" {
name_prefix        = "webapp-instance-template-" # since it creates before destroying 
description = "WebApp Regional Compute Instance Template"
region      = var.region
machine_type = var.machine_type
tags = ["webapp-vm"]
can_ip_forward = false
disk {
source_image = var.boot_disk_image
auto_delete = true 
boot = true 
disk_size_gb = var.boot_disk_size
type  = var.boot_disk_type
}
scheduling {
    automatic_restart   = true #Compute Engine will automatically restart the instance if it is terminated unexpectedly. 
    on_host_maintenance = "MIGRATE" #The instance will be migrated to another host system during maintenance. 
  }
network_interface {
network = google_compute_network.webapp_vpc_network.self_link
subnetwork = google_compute_subnetwork.webapp_subnet1.self_link
access_config {}
}
service_account {
email  = google_service_account.webapp_service_account.email
scopes = var.service_account_scope
}

lifecycle {
    create_before_destroy = true #check link documentation above main resource block for future reference
  }

metadata = {
startup-script = <<-EOF
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
}

resource "google_compute_health_check" "autohealing_health_check" {
  name                = "autohealing-health-check"
  check_interval_sec  = 20 #health check will be performed every x seconds
  timeout_sec         = 5  #if the instance does not respond within x seconds, it will be considered unhealthy.
  healthy_threshold   = 2 # the instance must pass x consecutive health checks to be considered healthy.
  unhealthy_threshold = 2 # if the instance fails x consecutive health checks, it will be marked as unhealthy.

  tcp_health_check {
    request = "/healthz" 
    port         = "8000"
    port_name = "tcp-port"
  }
}

resource "google_compute_region_instance_group_manager" "mig_webapp" {
  name = "mig-webapp"
  base_instance_name         = "webapp"
  region                     = "us-central1"
  version {
    instance_template = google_compute_region_instance_template.webapp_instance_template.self_link
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.autohealing_health_check.id
    initial_delay_sec = 300 #delay before the group starts to recreate unhealthy instances after they are detected as unhealthy
  }

  named_port {
    name="http"
    port = 8000
  }

}
resource "google_compute_region_autoscaler" "my_region_autoscaler" {
  name   = "my-region-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.mig_webapp.self_link

  autoscaling_policy {
    max_replicas    = 6
    min_replicas    = 3
    cooldown_period = 60 #time autoscaler waits to collect new info from mig
    cpu_utilization {
      target = 0.05 #5% as per assignment req
    }
  }
}

# Firewall rule to allow traffic to application port
resource "google_compute_firewall" "webapp_firewall" {
  name    = var.allow_rule_name
  network = google_compute_network.webapp_vpc_network.self_link

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
  network = google_compute_network.webapp_vpc_network.self_link

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
      private_network = google_compute_network.webapp_vpc_network.self_link
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
  network = google_compute_network.webapp_vpc_network.self_link

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

/*
# Compute Engine instance
resource "google_compute_instance" "web_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["webapp-vm"]
  allow_stopping_for_update = true

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
    scopes = var.service_account_scope  
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

*/

# Update DNS records
resource "google_dns_record_set" "webapp_dns_record" {
  managed_zone = var.dns_managed_zone
  name    = var.domain_name
  type    = var.dns_record_type
  ttl     = var.dns_record_ttl
  rrdatas = [google_compute_global_address.webapp_lb.address]

}

# Create Service Account
resource "google_service_account" "webapp_service_account" {
  account_id   = var.service_account_name
  display_name = var.service_account_display_name
}

# Bind IAM roles to the Service Account
resource "google_project_iam_binding" "vm_service_account_binding" {
  project = var.project_id
  role    = var.iam_role_binding1
  
  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}

resource "google_project_iam_binding" "vm_service_account_binding_monitoring" {
  project = var.project_id
  role    = var.iam_role_binding2
  
  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}

# Create Pub/Sub topic
resource "google_pubsub_topic" "verify_email_topic" {
  name = var.pubsub_topic_name
  message_retention_duration = var.message_retention_duration

  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}

# Create Pub/Sub subscription for the Cloud Function
resource "google_pubsub_subscription" "verify_email_subscription" {
  name  = var.google_pubsub_subscription_name
  topic = google_pubsub_topic.verify_email_topic.name
}

# Bind IAM role to the service account to publish messages to the Pub/Sub topic
resource "google_project_iam_binding" "pubsub_publisher_binding" {
  project = var.project_id
  role    = var.iam_role_binding_3

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}


resource "google_cloudfunctions2_function" "pubsub_process" {
  name        = var.cloud_fucntion_name
  location      = var.cloud_function_location
  description = var.cloud_function_description
  build_config {
    runtime     = var.cloud_function_runtime
    entry_point = var.cloud_function_entry_point
    source {
      storage_source {
        bucket = var.cloud_function_bucket
        object = var.cloud_function_object
      }
    }
  }
  service_config {
    max_instance_count = var.service_config_max_instance_count
    min_instance_count = var.service_config_min_instance_count
    available_memory   = var.service_config_available_memory
    timeout_seconds    = var.timeout_seconds
    environment_variables = {
    DB_HOST = google_sql_database_instance.main_primary.private_ip_address
    DB_USER = google_sql_user.cloudsql_user.name
    DB_PASS = google_sql_user.cloudsql_user.password
    DB_NAME = google_sql_database.main.name
    }

    ingress_settings               = var.cloud_function_ingress_settings
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.webapp_service_account.email
    vpc_connector = google_vpc_access_connector.vpc_connector.id

  }
  event_trigger {
    trigger_region = var.event_trigger_region
    event_type     = var.event_trigger_event_type
    pubsub_topic   = google_pubsub_topic.verify_email_topic.id
    retry_policy   = var.event_trigger_retry_policy
  }

 # depends_on = [
 #   google_sql_database_instance.main_primary,
 #   google_sql_user.cloudsql_user,
 #   google_pubsub_topic.verify_email_topic
 # ]
}

resource "google_vpc_access_connector" "vpc_connector" {
  name                   = var.vpc_connector_name
  region                 = var.vpc_connector_region
  network                = google_compute_network.webapp_vpc_network.name
  ip_cidr_range          = var.vpc_connector_cidr_range
  min_instances          = var.vpc_connector_min_instances
  max_instances          = var.vpc_connector_max_instances
}

resource "google_compute_backend_service" "webapp_backend" {
  name                    = "webapp-backend-service"
  protocol                = "HTTP"
  timeout_sec             = 30
  port_name               = "http"
  enable_cdn              = false
  health_checks = [google_compute_health_check.autohealing_health_check.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy = "ROUND_ROBIN"
   log_config {
    enable      = true
    sample_rate = 1
  }
  backend {
    group = google_compute_region_instance_group_manager.mig_webapp.instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# Google managed ssl cert (if you're planning to use regional resources, try ssl cert from namecheap)
resource "google_compute_managed_ssl_certificate" "webapp_ssl" {
  name = "webapp-ssl"

  managed {
    domains = ["siddharthdash.me"]
  }
}

# global static IP address that will be used for the load balancer
resource "google_compute_global_address" "webapp_lb" {
  name = "webapp-lb"
}

/*When a request arrives at the load balancer, the load balancer routes the request to a 
particular backend service or a backend bucket based on the rules defined in the URL map.*/
#In my case I just have a single backend service, so setting default service as the backend service

resource "google_compute_url_map" "webapp_url_map" {
  name            = "webapp-url-map"
  default_service = google_compute_backend_service.webapp_backend.self_link
}

/*HTTPS Proxy handles SSL termination and forwards requests to backend services based on the rules defined in the URL Map,
 which determines how incoming requests are routed to backend services. */
resource "google_compute_target_https_proxy" "webapp_target_proxy" {
  name        = "webapp-target-proxy"
  url_map     = google_compute_url_map.webapp_url_map.self_link
  depends_on = [ google_compute_managed_ssl_certificate.webapp_ssl ]
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp_ssl.id]
}

#forwarding rule : specifies the target proxy to which the traffic should be directed
resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name       = "webapp-forwarding-rule"
  target     = google_compute_target_https_proxy.webapp_target_proxy.self_link
  port_range = "443"
  ip_protocol = "TCP"
  ip_address = google_compute_global_address.webapp_lb.self_link
  load_balancing_scheme = "EXTERNAL_MANAGED" #may or may not need an explicit compute global address for lb ip since i am using external managed
}

#allow health check probes from Google's infrastructure
resource "google_compute_firewall" "webapp_firewall_healthcheck" {
  name    = "webapp-firewall-healthcheck"
  network = google_compute_network.webapp_vpc_network.self_link
  priority = 500
  allow {
    protocol = "all"
}
 source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] #source ranges where google's health checks originate from
 destination_ranges = [var.webapp_subnet_cidr] 
 direction = "INGRESS"
}

resource "google_compute_firewall" "inbound_denyall" {
  name    = "inbound-denyall"
  network = google_compute_network.webapp_vpc_network.self_link
  priority = 900
  deny {
    protocol = "all"  
  }
  source_ranges = ["0.0.0.0/0"] 
}