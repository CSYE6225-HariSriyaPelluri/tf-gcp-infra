provider "google" {
  project = var.project_id
  region  = var.region
}
/* Reference: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network*/
resource "google_compute_network" "custom_vpc" {
  name                            = var.vpc_details.vpc_name
  auto_create_subnetworks         = var.vpc_details.auto_create_subnetworks
  delete_default_routes_on_create = var.vpc_details.delete_default_routes_on_create
  routing_mode                    = var.vpc_details.routing_mode
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
  priority         = var.route_prioroty
  tags             = [var.tag_name]

}

resource "google_compute_firewall" "firewall_custom_vpc" {
  name    = var.firewall_name
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = var.protocol.name
    ports    = [var.protocol.port]
  }

  priority      = var.protocol.priority
  source_ranges = [var.firewall_src_range]
  target_tags   = [var.tag_name]
}

resource "google_compute_firewall" "firewall_deny_ssh" {
  name    = var.deny_all_firewall
  network = google_compute_network.custom_vpc.id

  deny {
    protocol = "all"
  }

  priority      = var.allpriority
  source_ranges = [var.firewall_src_range]

}
data "google_compute_image" "latest_image" {
  family      = var.image_family
  most_recent = var.instance_parameters.most_recent

}

resource "google_compute_instance" "custom_instance" {
  name         = var.instance_parameters.instance_name
  machine_type = var.instance_parameters.machine_type
  zone         = var.instance_parameters.zone

  network_interface {
    network    = google_compute_network.custom_vpc.id
    subnetwork = google_compute_subnetwork.subnets[var.instance_parameters.subnetname].id
    access_config {
      network_tier = var.instance_parameters.network_tier
    }
  }

  tags = [var.tag_name]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.latest_image.self_link
      size  = var.instance_parameters.size
      type  = var.instance_parameters.type
    }
  }

}


