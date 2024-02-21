variable "project_id" {
  description = "The GCP project ID"
}

variable "region" {
  description = "The GCP region where resources will be created"
  default     = "us-east1"
}

variable "vpc_name" {
  description = "The name of the VPC"
  default     = "my-custom-vpc"
}

variable "dest_cidr" {
  description = "CIDR route for webapp subnet"
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

variable "tag_name" {
  description = "Name of the tag in route"
  default     = "tag"
}

variable "route_name" {
  description = "Name of route"
  default     = "webapp-route"
}

variable "routing_mode" {
  description = "Specifying routing mode of network"
  default     = "REGIONAL"
}

variable "auto_create_subnetworks" {
  description = "Should subnetworks be auto created or not"
  default     = false
}

variable "delete_default_routes_on_create" {
  description = "Boolean to determine default routes should be created or not"
  default     = true
}
variable "next_hop_gateway" {
  description = "Next Hop Gateway Value"
  default     = "default-internet-gateway"
}

variable "firewall_name" {
  description = "Firewall name for the custom VPC created"
  default     = "custom-firewall"
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
    http_tag      = string
    subnetname    = string
    size          = string
    type          = string
    network_tier  = string
  })
}

variable "protocol" {
  description = "Protocols to use"
  type = object({
    name = string
    port = string
  })
  default = {
    name = "protocol"
    port = "port number"
  }
}

variable "firewall_src_range" {
  description = "Source range of firewalls"
  default     = "0.0.0.0/0"
}

variable "network_tier" {
  description = "Network Tier"
  default     = "PREMIUM"
}