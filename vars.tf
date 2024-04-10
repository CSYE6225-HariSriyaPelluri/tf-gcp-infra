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
    most_recent         = bool
    instance_name       = string
    zone                = string
    machine_type        = string
    subnetname          = string
    size                = string
    type                = string
    network_tier        = string
    automatic_restart   = bool
    min_node_cpus       = number
    on_host_maintenance = string
    preemptible         = bool
    provisioning_model  = string
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


variable "sql_instance_params" {
  description = "Fields required to create SQL instance"

  type = object({
    private_ip_name              = string
    name                         = string
    address_type                 = string
    address                      = string
    sql_subnet                   = string
    dbver                        = string
    tier                         = string
    availability_type            = string
    disk_type                    = string
    disk_size                    = number
    backup_configuration_enabled = bool
    backup_configuration_log     = bool
    psc_enabled                  = bool
    ipv4_enabled                 = bool
    deletion_protection          = bool
    db_name                      = string
    sqlport                      = number
    user                         = string
    passwordlength               = number
    specialchar                  = bool
  })
  default = {
    private_ip_name              = "private-ip-address-psc"
    name                         = "cloud-sql-instance-webapp"
    address_type                 = "INTERNAL"
    address                      = "10.0.2.3"
    sql_subnet                   = "db5test"
    dbver                        = "MYSQL_8_0"
    tier                         = "db-f1-micro"
    availability_type            = "REGIONAL"
    disk_type                    = "pd-ssd"
    disk_size                    = 100
    backup_configuration_enabled = true
    backup_configuration_log     = true
    psc_enabled                  = true
    ipv4_enabled                 = false
    deletion_protection          = false
    db_name                      = "webapp"
    sqlport                      = 3306
    user                         = "webapp"
    passwordlength               = 16
    specialchar                  = false
  }

}

variable "service_account_id" {
  type    = string
  default = "vm-sa-logging"
}

variable "service_account_display_name" {
  type    = string
  default = "Custom SA for VM Instance"
}

variable "roles" {
  type    = list(string)
  default = ["roles/logging.admin", "roles/monitoring.metricWriter", "roles/pubsub.publisher"]
}

variable "zone_name" {
  type    = string
  default = "webapp"
}

variable "sa_scope" {
  type    = string
  default = "cloud-platform"
}

variable "record_details" {
  type = object({
    name = string
    type = string
    ttl  = number
  })

  default = {
    name = "harisriya.me."
    type = "A",
    ttl  = 300
  }
}

variable "pub_sub_params" {
  type = object({
    topic_name                 = string
    subscription_name          = string
    sa_name                    = string
    sa_display_name            = string
    sub_sa_name                = string
    sub_sa_display_name        = string
    topic_role                 = string
    sub_role                   = string
    message_retention_duration = string
  })

  default = {
    topic_name                 = "verify_email"
    subscription_name          = "verify_email_subscription"
    sa_name                    = "topic-for-cf"
    sa_display_name            = "Topic for cloud function"
    sub_sa_name                = "subscriber-for-cf"
    sub_sa_display_name        = "Subscriber for cloud Function"
    topic_role                 = "roles/viewer"
    sub_role                   = "roles/editor"
    message_retention_duration = "604800s"
  }
}

variable "bucket_params" {
  type = object({
    obj_name                    = string
    content_type                = string
    file_op_path                = string
    file_src_path               = string
    uniform_bucket_level_access = bool
  })

  default = {
    obj_name                    = "cloudfunctioncode"
    content_type                = "application/zip"
    file_op_path                = "/tmp/function-source.zip"
    file_src_path               = "../serverless_dev/"
    uniform_bucket_level_access = true

  }
}

variable "cloud_fn_params" {
  type = object({
    name                 = string
    description          = string
    runtime              = string
    entry_point          = string
    event_type           = string
    retry_policy         = string
    sa_acc_name          = string
    sa_display_name      = string
    sa_role              = string
    vpc_acc_connect_name = string
    vpc_acc_connect_cidr = string
    sql_role             = string
  })

  default = {
    name                 = "verify-email"
    description          = "Cloud Function to send verification email to users"
    runtime              = "nodejs18"
    entry_point          = "helloPubSub"
    event_type           = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy         = "RETRY_POLICY_RETRY"
    sa_acc_name          = "cloud-function-service-account"
    sa_display_name      = "Cloud Function Service Account"
    sa_role              = "roles/run.invoker"
    vpc_acc_connect_name = "cloudconnector"
    vpc_acc_connect_cidr = "10.10.0.0/28"
    sql_role             = "roles/cloudsql.client"
  }

}

variable "MAILGUN_API_KEY" {
  type = string
}

variable "DOMAIN" {
  type = string
}

variable "backend_service_params" {
  type = object({
    name            = string
    port_name       = string
    protocol        = string
    enable_cdn      = bool
    balancing_mode  = string
    capacity_scaler = number
  })
  default = {
    name            = "backend-service"
    port_name       = "my-port"
    protocol        = "HTTP"
    enable_cdn      = true
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

variable "health_check_firewall_params" {
  type = object({
    name          = string
    source_ranges = list(string)
  })
  default = {
    name          = "allow-health-check"
    source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  }
}

variable "target_proxy_name" {
  type    = string
  default = "lb-https-proxy"
}

variable "ssl_name" {
  type    = string
  default = "value"
}

variable "url_name" {
  type    = string
  default = "l7-xlb-url-map"
}

variable "auto_scaler_params" {
  type = object({
    name                   = string
    max_replicas           = number
    min_replicas           = number
    cooldown_period        = number
    cpu_utilization_target = number
  })
  default = {
    name                   = "my-region-autoscaler"
    max_replicas           = 6
    min_replicas           = 3
    cooldown_period        = 60
    cpu_utilization_target = 0.05
  }
}

variable "health_check" {
  type = object({
    name                = string
    description         = string
    timeout_sec         = number
    check_interval_sec  = number
    healthy_threshold   = number
    unhealthy_threshold = number
    request_path        = string
    port                = number
  })
  default = {
    name                = "https-health-check"
    description         = "Health check via https"
    timeout_sec         = 1
    check_interval_sec  = 5
    healthy_threshold   = 2
    unhealthy_threshold = 10
    request_path        = "/healthz"
    port                = 8080
  }
}

variable "instance_group_manager_params" {
  type = object({
    name               = string
    base_instance_name = string
    dis_zone           = string
    port_name          = string
    port               = number
    target_size        = number
    initial_delay_sec  = number
  })
  default = {
    name               = "appserver-igm"
    base_instance_name = "app"
    dis_zone           = "us-east1-c"
    port_name          = "my-port"
    port               = 8080
    target_size        = 2
    initial_delay_sec  = 300
  }
}

variable "load_balancer_params" {
  type = object({
    global_add_name      = string
    ip_version           = string
    address_type         = string
    port_range           = string
    forwarding_rule_name = string
  })
  default = {
    global_add_name      = "global-lb-address"
    ip_version           = "IPV4"
    address_type         = "EXTERNAL"
    port_range           = "443"
    forwarding_rule_name = "lb-https-rule"
  }
}

variable "ssl_domain" {
  type    = string
  default = "harisriya.me."
}

variable "key_ring_name" {
  type    = string
  default = "test-one-ring"
}

variable "keys_params" {
  type = object({
    vm_ins_key      = string
    rotation_period = string
    crypto_role     = string
    cloudsql_key    = string
    storage_key     = string
    bucket_service  = string
    sql_service     = string
    vm_sa           = list(string)
  })
}

