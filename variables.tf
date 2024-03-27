variable "project_id" {}
variable "region" {}
variable "vpc_name" {}
variable "webapp_subnet_name" {}
variable "webapp_subnet_cidr" {}
variable "db_subnet_name" {}
variable "db_subnet_cidr" {}
variable "webapp_route_name" {}
variable "internet_gateway_name" {}
variable "application_port" {}
variable "zone" {}
variable "allowed_ips" {
  type = list(string)
  default = ["0.0.0.0/0"]
}
variable "routing_mode_vpc" {}
variable "next_hop_gateway" {}
variable "route_dest_range" {}
variable "allow_rule_name" {}
variable "instance_name" {}
variable "machine_type" {}
variable "boot_disk_image" {}
variable "boot_disk_size" {
    type = number 
}
variable boot_disk_type {}
variable vpc_peering_blockname {}
variable vpc_peering_purpose {}
variable vpc_peering_address_type {}
variable vpc_peering_ip_version {}
variable vpc_peering_prefix_length {}

variable sql_instance_database_version {}
variable sql_instance_database_region {}
variable sql_instance_database_tier {}
variable sql_instance_database_availability_type {
    type = string 
    default = "REGIONAL"
}
variable sql_instance_database_disk_size {
    type = number
    default = 100
}
variable sql_instance_database_disk_type {
    type = string
    default = "pd-ssd"
}

variable sql_instance_database_ip4enabled {
    type = bool
    default = false
}

variable sql_instance_database_deletion_protection {
    type = bool 
    default = false 
}

variable database_name {}
variable database_firewall_name {}
variable dns_managed_zone {}
variable domain_name {}
variable dns_record_type {}
variable dns_record_ttl {}
variable service_account_name {}
variable service_account_display_name {}
variable iam_role_binding1 {}
variable iam_role_binding2 {}
variable service_account_scope {
    type = list(string)
}
variable cloud_fucntion_name {} 
variable cloud_function_location {}
variable cloud_function_description {
  
}
variable cloud_function_runtime {
  
}
variable cloud_function_entry_point {
  
}
variable cloud_function_bucket {
  
}
variable cloud_function_object {
  
}

variable service_config_max_instance_count {
  
}

variable service_config_min_instance_count {
  
}

variable service_config_available_memory {
  
}

variable timeout_seconds {
  
}

variable cloud_function_ingress_settings {
  
}

variable event_trigger_region {
  
}

variable event_trigger_event_type {
  
}

variable event_trigger_retry_policy {
  
}

variable vpc_connector_name {
  
}

variable vpc_connector_region {
  
}

variable vpc_connector_cidr_range {
  
}

variable vpc_connector_min_instances {
  
}

variable vpc_connector_max_instances {
  
}

variable iam_role_binding_3 {
  
}

variable google_pubsub_subscription_name {
  
}

variable pubsub_topic_name {
  
}

variable message_retention_duration {}