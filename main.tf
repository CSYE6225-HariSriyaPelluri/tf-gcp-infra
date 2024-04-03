terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
      
    }
  }
}

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
  source_ranges = [google_compute_global_address.lb_ip_address.address]
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

# Private IP Address for SQL Instance
resource "google_compute_address" "private_ip_address" {
  name         = var.sql_instance_params.private_ip_name
  region       = var.region
  address_type = var.sql_instance_params.address_type
  subnetwork   = resource.google_compute_subnetwork.subnets[var.sql_instance_params.sql_subnet].name
  address      = var.sql_instance_params.address
}

# Cloud SQL MySQL Instance
resource "google_sql_database_instance" "sql_instance" {
  name             = var.sql_instance_params.name
  region           = var.region
  database_version = var.sql_instance_params.dbver
  settings {
    tier = var.sql_instance_params.tier

    availability_type = var.sql_instance_params.availability_type

    disk_type = var.sql_instance_params.disk_type
    disk_size = var.sql_instance_params.disk_size

    backup_configuration {
      enabled            = var.sql_instance_params.backup_configuration_enabled
      binary_log_enabled = var.sql_instance_params.backup_configuration_log
    }
    ip_configuration {
      psc_config {
        psc_enabled               = var.sql_instance_params.psc_enabled
        allowed_consumer_projects = [var.project_id]
      }
      ipv4_enabled = var.sql_instance_params.ipv4_enabled
    }
  }

  deletion_protection = var.sql_instance_params.deletion_protection
}

data "google_sql_database_instance" "default" {
  name = google_sql_database_instance.sql_instance.name
}

resource "google_compute_forwarding_rule" "default" {
  name                  = "psc-forwarding-rule-${google_sql_database_instance.sql_instance.name}"
  region                = var.region
  network               = google_compute_network.custom_vpc.self_link
  ip_address            = google_compute_address.private_ip_address.self_link
  load_balancing_scheme = ""
  target                = data.google_sql_database_instance.default.psc_service_attachment_link
}

# Cloud SQL Database
resource "google_sql_database" "webapp_database" {
  name     = var.sql_instance_params.db_name
  instance = google_sql_database_instance.sql_instance.name
}

resource "random_password" "pwd" {
  length  = var.sql_instance_params.passwordlength
  special = var.sql_instance_params.specialchar
}

resource "google_sql_user" "webapp_user" {
  name     = var.sql_instance_params.user
  instance = google_sql_database_instance.sql_instance.name
  password = random_password.pwd.result
}

data "google_compute_image" "latest_image" {
  family      = var.image_family
  most_recent = var.instance_parameters.most_recent

}

# Service account for VM
resource "google_service_account" "default" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

data "google_service_account" "vm_service_account" {
  account_id = var.service_account_id
  depends_on = [google_service_account.default]
}

# IAM Bindings
resource "google_project_iam_binding" "iam_binding" {
  for_each = { for role in var.roles : role => role }

  project = var.project_id
  role    = each.value

  members = [
    "serviceAccount:${data.google_service_account.vm_service_account.email}"
  ]
}

# Use the existing Cloud DNS zone named "webapp"
data "google_dns_managed_zone" "existing_zone" {
  name = var.zone_name
}

resource "google_compute_region_instance_template" "custom_instance" {
  name         = var.instance_parameters.instance_name
  machine_type = var.instance_parameters.machine_type
  region       = var.region


  network_interface {
    network    = google_compute_network.custom_vpc.id
    subnetwork = google_compute_subnetwork.subnets[var.instance_parameters.subnetname].id
    access_config {
      network_tier = var.instance_parameters.network_tier
    }
  }
  tags = [var.tag_name]

  depends_on = [google_service_account.default]
  disk {
    source_image = data.google_compute_image.latest_image.self_link
    type         = var.instance_parameters.type
    auto_delete  = true
    boot         = true
  }

  scheduling {
    automatic_restart   = var.instance_parameters.automatic_restart
    min_node_cpus       = var.instance_parameters.min_node_cpus
    on_host_maintenance = var.instance_parameters.on_host_maintenance
    preemptible         = var.instance_parameters.preemptible
    provisioning_model  = var.instance_parameters.provisioning_model
  }


  metadata_startup_script = templatefile("${path.module}/startupscript.sh.tpl", {
    hostname = google_compute_address.private_ip_address.address,
    username = google_sql_user.webapp_user.name,
    password = google_sql_user.webapp_user.password,
    db       = google_sql_database.webapp_database.name,
    port     = var.protocol.port
  })

  service_account {
    email  = google_service_account.default.email
    scopes = [var.sa_scope]
  }

}

resource "google_compute_health_check" "https-health-check" {
  name        = var.health_check.name
  description = var.health_check.description

  timeout_sec         = var.health_check.timeout_sec
  check_interval_sec  = var.health_check.check_interval_sec
  healthy_threshold   = var.health_check.healthy_threshold
  unhealthy_threshold = var.health_check.unhealthy_threshold

  http_health_check {
    request_path = var.health_check.request_path
    port         = var.health_check.port
  }

}

resource "google_compute_region_instance_group_manager" "appserver" {
  name = var.instance_group_manager_params.name

  base_instance_name        = var.instance_group_manager_params.base_instance_name
  region                    = var.region
  distribution_policy_zones = [var.instance_parameters.zone, var.instance_group_manager_params.dis_zone]

  version {
    instance_template = google_compute_region_instance_template.custom_instance.id
  }
  named_port {
    name = var.instance_group_manager_params.port_name
    port = var.instance_group_manager_params.port
  }

  target_size = var.instance_group_manager_params.target_size


  auto_healing_policies {
    health_check      = google_compute_health_check.https-health-check.id
    initial_delay_sec = var.instance_group_manager_params.initial_delay_sec
  }
}


resource "google_compute_region_autoscaler" "autoscaler" {
  name   = var.auto_scaler_params.name
  region = var.region
  target = google_compute_region_instance_group_manager.appserver.self_link

  autoscaling_policy {
    max_replicas    = var.auto_scaler_params.max_replicas
    min_replicas    = var.auto_scaler_params.min_replicas
    cooldown_period = var.auto_scaler_params.cooldown_period

    cpu_utilization {
      target = var.auto_scaler_params.cpu_utilization_target
    }
  }
}

resource "google_compute_firewall" "allow_health_checks" {
  name          = var.health_check_firewall_params.name
  network       = google_compute_network.custom_vpc.id
  source_ranges = var.health_check_firewall_params.source_ranges
  allow {
    protocol = var.protocol.name
    ports    = [var.protocol.port]
  }

  target_tags = [var.tag_name]
}

resource "google_service_account" "forwarding_rule_lb_service_account" {
  account_id   = var.forwarding_rule_lb_service_account.sa_acc_name
  display_name = var.forwarding_rule_lb_service_account.sa_display_name
}
resource "google_compute_global_address" "lb_ip_address" {
  name         = var.load_balancer_params.global_add_name
  ip_version   = var.load_balancer_params.ip_version
  address_type = var.load_balancer_params.address_type
}

resource "google_compute_global_forwarding_rule" "https" {
  provider   = google-beta
  project    = var.project_id
  name       = var.load_balancer_params.forwarding_rule_name
  target     = google_compute_target_https_proxy.default.self_link
  ip_address = google_compute_global_address.lb_ip_address.address
  port_range = var.load_balancer_params.port_range
  depends_on = [google_compute_global_address.lb_ip_address]
}

resource "google_compute_backend_service" "backend_service" {
  name          = var.backend_service_params.name
  health_checks = [google_compute_health_check.https-health-check.id]
  port_name     = var.backend_service_params.port_name
  protocol      = var.backend_service_params.protocol

  enable_cdn = var.backend_service_params.enable_cdn
  backend {
    group           = google_compute_region_instance_group_manager.appserver.instance_group
    balancing_mode  = var.backend_service_params.balancing_mode
    capacity_scaler = var.backend_service_params.capacity_scaler
  }

}

#url map
resource "google_compute_url_map" "default" {
  name            = var.url_name
  project         = var.project_id
  provider        = google-beta
  default_service = google_compute_backend_service.backend_service.id
}
resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  provider = google-beta
  project  = var.project_id
  name     = var.ssl_name

  managed {
    domains = [var.ssl_domain]
  }
}
resource "google_compute_target_https_proxy" "default" {
  name             = var.target_proxy_name
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_certificate.self_link]
  depends_on = [
    google_compute_managed_ssl_certificate.ssl_certificate
  ]
}

resource "google_dns_record_set" "domain_record" {
  name         = var.record_details.name
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  type         = var.record_details.type
  ttl          = var.record_details.ttl
  rrdatas      = [google_compute_global_address.lb_ip_address.address]
}


#Topic Service Account
resource "google_service_account" "topic_service_account" {
  account_id   = var.pub_sub_params.sa_name
  display_name = var.pub_sub_params.sa_display_name
}

# Grant roles to the Topic Service Account
resource "google_project_iam_member" "topic_viewer" {
  project = var.project_id
  role    = var.pub_sub_params.topic_role
  member  = "serviceAccount:${google_service_account.topic_service_account.email}"
}

// Pub/Sub Topic
resource "google_pubsub_topic" "verify_email_topic" {
  name                       = var.pub_sub_params.topic_name
  message_retention_duration = var.pub_sub_params.message_retention_duration
}

# Subscription Service Account
resource "google_service_account" "sub_service_account" {
  account_id   = var.pub_sub_params.sub_sa_name
  display_name = var.pub_sub_params.sub_sa_display_name
}

# Grant roles to the Subscription Service Account
resource "google_project_iam_member" "sub_editor" {
  project = var.project_id
  role    = var.pub_sub_params.sub_role
  member  = "serviceAccount:${google_service_account.sub_service_account.email}"
}

// Pub/Sub Subscription
resource "google_pubsub_subscription" "verify_email_subscription" {
  name                 = var.pub_sub_params.subscription_name
  topic                = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = 10
}

resource "random_id" "default" {
  byte_length = 8
}
# Create a Cloud Storage bucket
resource "google_storage_bucket" "cf_bucket" {
  name                        = "${random_id.default.hex}-gcf-source"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = var.bucket_params.uniform_bucket_level_access
}

data "archive_file" "default" {
  type        = "zip"
  output_path = var.bucket_params.file_op_path
  source_dir  = var.bucket_params.file_src_path
}
# Upload zip file to Cloud Storage
resource "google_storage_bucket_object" "function_zip" {
  name         = var.bucket_params.obj_name
  content_type = var.bucket_params.content_type
  bucket       = google_storage_bucket.cf_bucket.name
  source       = data.archive_file.default.output_path
  depends_on   = [google_storage_bucket.cf_bucket]
}

# Cloud Function Service Account
resource "google_service_account" "cf_service_account" {
  account_id   = var.cloud_fn_params.sa_acc_name
  display_name = var.cloud_fn_params.sa_display_name
}

# Grant roles to the Cloud Function Service Account
resource "google_project_iam_member" "pubsub_invoker" {
  project = var.project_id
  role    = var.cloud_fn_params.sa_role
  member  = "serviceAccount:${google_service_account.cf_service_account.email}"
}


resource "google_project_iam_member" "sql_client" {
  project = var.project_id
  role    = var.cloud_fn_params.sql_role
  member  = "serviceAccount:${google_service_account.cf_service_account.email}"
}
resource "google_vpc_access_connector" "cloud_function_vpc_connector" {
  name          = var.cloud_fn_params.vpc_acc_connect_name
  region        = var.region
  network       = google_compute_network.custom_vpc.name
  ip_cidr_range = var.cloud_fn_params.vpc_acc_connect_cidr
}


# Cloud Function
resource "google_cloudfunctions2_function" "verify_email_function" {
  name        = var.cloud_fn_params.name
  location    = var.region
  description = var.cloud_fn_params.description
  build_config {
    runtime     = var.cloud_fn_params.runtime
    entry_point = var.cloud_fn_params.entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.cf_bucket.name
        object = google_storage_bucket_object.function_zip.name
      }
    }

  }

  service_config {
    vpc_connector = google_vpc_access_connector.cloud_function_vpc_connector.name
    environment_variables = {
      MAILGUN_API_KEY = var.MAILGUN_API_KEY,
      DOMAIN          = var.DOMAIN,
      hostname        = google_compute_address.private_ip_address.address,
      username        = google_sql_user.webapp_user.name,
      password        = google_sql_user.webapp_user.password,
      db              = google_sql_database.webapp_database.name
    }

    service_account_email = google_service_account.cf_service_account.email
  }
  project = var.project_id

  event_trigger {
    trigger_region        = var.region
    event_type            = var.cloud_fn_params.event_type
    pubsub_topic          = google_pubsub_topic.verify_email_topic.id
    service_account_email = google_service_account.cf_service_account.email
    retry_policy          = var.cloud_fn_params.retry_policy
  }


  depends_on = [google_storage_bucket.cf_bucket]
}