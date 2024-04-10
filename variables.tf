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

variable instance_template_name_prefix {}
variable instance_template_description {} 
variable instance_template_scheduling_maintenance {}
variable health_check_name {}
variable health_check_check_interval_sec {}
variable health_check_timeout_sec {
  
}
variable health_check_healthy_threshold {}
variable health_check_unhealthy_threshold {}
variable tcp_health_check_endpoint {}
variable tcp_health_check_port {}
variable tcp_health_check_port_name {}
variable instance_region_group {}
variable instance_group_name {}
variable instance_group_base_instance_name {}
variable instance_group_region {}
variable instance_group_autohealing_initial_delay_seconds {}
variable instance_group_named_port_name {}
variable instance_group_named_port_number {
  
}
variable autoscale_name {}
variable autoscale_region {}
variable autoscaling_policy_max_replicas {}
variable autoscaling_policy_min_replicas {}
variable autoscaling_policy_cooldown_period {}
variable autoscaling_cpu_utilization_target {}

variable backend_service_name {}
variable backend_service_protocol {}
variable backend_service_timeout_sec {}
variable backend_service_port_name {}
variable backend_service_load_balancing_scheme {}
variable backend_service_lb_policy {}
variable backend_service_log_config_sample_rate {}
variable backend_service_balancing_mode {}
variable backend_service_capacity_scaler {}
variable ssl_certificate_name {}
variable ssl_domain {}
variable webapp_lb {}
variable webapp_url_map_name {}
variable webapp_target_proxy_name {}
variable webapp_forwarding_rule_name {}
variable webapp_forwarding_rule_port_range {
  
}
variable webapp_forwarding_rule_ip_protocol {}
variable forwarding_rule_load_balancing_scheme {}
variable healthcheck_firewall_name {}
variable healthcheck_firewall_priority {}
variable healthcheck_firewall_sourceranges {
    type = list(string)
}
variable healthcheck_firewall_protocol {}
variable healthcheck_firewall_direction {}
variable inbound_denyall_firewall_name {}
variable inbound_denyall_firewall_priority {}
variable inbound_denyall_fireall_source_ranges{
    type = list(string)
}
variable inbound_denyall_firewall_protocol {}
variable service_identity {}
variable bucket_name {}
variable bucket_object{}
variable bucket_object_source{}
variable vm_keyname {}
variable rotation_period_key{}
variable sql_keyname{}
variable storage_keyname{}
variable cryptoKeyEncrypterDecrypterrole{}
variable compute_system_service_identity {}
variable gs_project_accounts_service_identity{}
