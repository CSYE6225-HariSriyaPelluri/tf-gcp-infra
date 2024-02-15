provider "google" {
  project = var.project_id
  region  = var.region
}
/* Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network*/
resource "google_compute_network" "custom_vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  routing_mode                    = "REGIONAL"
}

/* Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork*/
resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                     = each.value.name
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.custom_vpc.id
  private_ip_google_access = each.value.private_ip_google_access

}

resource "google_compute_route" "webapp_route" {
  name             = var.route_name
  dest_range       = var.dest_cidr
  network          = google_compute_network.custom_vpc.id
  next_hop_gateway = var.next_hop_gateway
  priority         = 1000
  tags             = [var.tag_name]

}

