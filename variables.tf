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

