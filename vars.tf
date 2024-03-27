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
  default = ["roles/logging.admin", "roles/monitoring.metricWriter","roles/pubsub.publisher"]
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
    topic_name = string
    subscription_name = string
    sa_name=string
    sa_display_name=string
    sub_sa_name=string
    sub_sa_display_name=string
    topic_role=string
    sub_role=string
  })

  default = {
    topic_name = "verify_email"
    subscription_name = "verify_email_subscription"
    sa_name = "topic-for-cf"
    sa_display_name="Topic for cloud function"
    sub_sa_name="subscriber-for-cf"
    sub_sa_display_name="Subscriber for cloud Function"
    topic_role = "roles/viewer"
    sub_role = "roles/editor"
  }
}

variable "bucket_params" {
  type = object({
    obj_name = string
    content_type = string
    file_op_path= string
    file_src_path = string
    uniform_bucket_level_access = bool
  })

  default = {
    obj_name = "cloudfunctioncode"
    content_type = "application/zip"
    file_op_path = "/tmp/function-source.zip"
    file_src_path = "../serverless_dev/"
    uniform_bucket_level_access = true

  }
}

variable "cloud_fn_params" {
  type = object({
    name = string
    description=string
    runtime=string
    entry_point=string
    event_type=string
    retry_policy=string
    sa_acc_name=string
    sa_display_name=string
    sa_role=string
    vpc_acc_connect_name=string
    vpc_acc_connect_cidr=string
  })

  default = {
    name = "verify-email"
    description = "Cloud Function to send verification email to users"
    runtime = "nodejs18"
    entry_point = "helloPubSub"
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    retry_policy = "RETRY_POLICY_RETRY"
    sa_acc_name = "cloud-function-service-account"
    sa_display_name = "Cloud Function Service Account"
    sa_role = "roles/cloudfunctions.invoker"
    vpc_acc_connect_name = "cloudconnector"
    vpc_acc_connect_cidr = "10.10.0.0/28"
  }
  
}

variable "MAILGUN_API_KEY" {
  type = string
}

variable "DOMAIN" {
  type = string
}