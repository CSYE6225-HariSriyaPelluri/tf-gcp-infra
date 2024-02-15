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
  default     = ""
}

variable "route_name" {
  description = "Name of route"
  default     = "webapp-route"
}

variable "next_hop_gateway" {
  description = "Next Hop Gateway Value"
  default = "default-internet-gateway"
}