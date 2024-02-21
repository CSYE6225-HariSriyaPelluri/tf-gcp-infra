variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region where resources will be created"
  default     = "us-east1"
}

variable "vpc_details" {
  description = "VPC fields"
  type = object({
    vpc_name                        = string
    routing_mode                    = string
    auto_create_subnetworks         = bool
    delete_default_routes_on_create = bool
  })
  default = {
    vpc_name                        = "my-custom-vpc"
    routing_mode                    = "REGIONAL"
    auto_create_subnetworks         = false
    delete_default_routes_on_create = true
  }
}

variable "subnets" {
  description = "List of subnets with their names, CIDR ranges and private ip google access state."
  type = list(object({
    name                     = string
    cidr                     = string
    private_ip_google_access = bool
  }))
  default = []
}

variable "dest_cidr" {
  description = "CIDR route for webapp subnet"
}
variable "tag_name" {
  description = "Name of the tag in route"
  default     = "tag"
}

variable "route_name" {
  description = "Name of route"
  default     = "webapp-route"
}

variable "route_prioroty" {
  description = "Priority of webapp route"
  type        = number
  default     = 1000
}
variable "next_hop_gateway" {
  description = "Next Hop Gateway Value"
  default     = "default-internet-gateway"
}

variable "firewall_name" {
  description = "Firewall name for the custom VPC created"
  default     = "custom-firewall"
}

variable "deny_all_firewall" {
  description = "Rule to deny ssh"
  default     = "denyssh"
}

variable "allpriority" {
  description = "Priority for all"
  type        = number
  default     = 65535
}

variable "image_family" {
  description = "Family of the Image being used"
  default     = "centos-8"
}
variable "instance_parameters" {
  description = "Fields for instance"
  type = object({
    most_recent   = bool
    instance_name = string
    zone          = string
    machine_type  = string
    subnetname    = string
    size          = string
    type          = string
    network_tier  = string
  })
}

variable "protocol" {
  description = "Protocols to use"
  type = object({
    name     = string
    port     = string
    priority = number
  })
  default = {
    name     = "protocol"
    port     = "port number"
    priority = 0
  }
}

variable "firewall_src_range" {
  description = "Source range of firewalls"
  default     = "0.0.0.0/0"
}