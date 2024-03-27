terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
      
    }
  }
}

provider "google"{
  project = var.project_id
  region = var.region
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

  depends_on = [google_service_account.default]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.latest_image.self_link
      size  = var.instance_parameters.size
      type  = var.instance_parameters.type
    }
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

resource "google_dns_record_set" "domain_record" {
  name         = var.record_details.name
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  type         = var.record_details.type
  ttl          = var.record_details.ttl
  rrdatas      = [google_compute_instance.custom_instance.network_interface[0].access_config[0].nat_ip]
}

# Topic Service Account
resource "google_service_account" "topic_service_account" {
  account_id   = var.pub_sub_params.sa_name
  display_name = var.pub_sub_params.sa_display_name
}

# Grant roles to the Topic Service Account
resource "google_project_iam_member" "topic_viewer" {
  project = var.project_id
  role   = var.pub_sub_params.topic_role
  member = "serviceAccount:${google_service_account.topic_service_account.email}"
}

// Pub/Sub Topic
resource "google_pubsub_topic" "verify_email_topic" {
  name = var.pub_sub_params.topic_name
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
  role   = var.pub_sub_params.sub_role
  member = "serviceAccount:${google_service_account.sub_service_account.email}"
}

// Pub/Sub Subscription
resource "google_pubsub_subscription" "verify_email_subscription" {
  name  = var.pub_sub_params.subscription_name
  topic = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = 10
}

resource "random_id" "default" {
  byte_length = 8
}
# Create a Cloud Storage bucket
resource "google_storage_bucket" "cf_bucket" {
  name     = "${random_id.default.hex}-gcf-source"
  project = var.project_id
  location = var.region
  uniform_bucket_level_access = var.bucket_params.uniform_bucket_level_access
}

data "archive_file" "default" {
  type        = "zip"
  output_path = var.bucket_params.file_op_path
  source_dir  = var.bucket_params.file_src_path
}
# Upload zip file to Cloud Storage
resource "google_storage_bucket_object" "function_zip" {
  name   = var.bucket_params.obj_name
  content_type = var.bucket_params.content_type
  bucket = google_storage_bucket.cf_bucket.name
  source = data.archive_file.default.output_path
  depends_on = [ google_storage_bucket.cf_bucket ]
}

# Cloud Function Service Account
resource "google_service_account" "cf_service_account" {
  account_id   = var.cloud_fn_params.sa_acc_name
  display_name = var.cloud_fn_params.sa_display_name
}

# Grant roles to the Cloud Function Service Account
resource "google_project_iam_member" "pubsub_invoker" {
  project = var.project_id
  role   = var.cloud_fn_params.sa_role
  member = "serviceAccount:${google_service_account.cf_service_account.email}"
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
  location = var.region
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
    vpc_connector         = google_vpc_access_connector.cloud_function_vpc_connector.name
    environment_variables = {
      MAILGUN_API_KEY = var.MAILGUN_API_KEY,
      DOMAIN = var.DOMAIN,
      hostname = google_compute_address.private_ip_address.address,
      username = google_sql_user.webapp_user.name,
      password = google_sql_user.webapp_user.password,
      db       = google_sql_database.webapp_database.name
    }

    service_account_email = google_service_account.cf_service_account.email
  }
  project     = var.project_id
  
  event_trigger {
    trigger_region = var.region
    event_type     = var.cloud_fn_params.event_type
    pubsub_topic   = google_pubsub_topic.verify_email_topic.id
    service_account_email = google_service_account.cf_service_account.email
    retry_policy = var.cloud_fn_params.retry_policy
  }

  
  depends_on = [ google_storage_bucket.cf_bucket ]
}