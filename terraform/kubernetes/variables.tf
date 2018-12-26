variable "ssh_public_key" {
  type    = "string"
}

variable "k8s_cluster_name" {
  type  = "string"
}

variable "k8s_master_nodes_count" {
  type  = "string"
  default = 0
}

variable "k8s_worker_nodes_count" {
  type  = "string"
  default = 0
}

variable "k8s_master_flavor" {
  type  = "string"
  default = "GP1.S"
}

variable "k8s_master_public_access" {
  type  = "string"
  default = 0
}

variable "k8s_master_private_access" {
  type  = "string"
  default = 0
}

variable "k8s_worker_flavor" {
  type  = "string"
  default = "GP1.M"
}

variable "k8s_operating_system_image" {
  type  = "string"
  default = "Ubuntu 18.04.1 (Bionic Beaver)"
}

variable "openstack_internal_network_cidr" {
  type = "string"
  default = "192.168.0.0/24"
}

variable "k8s_pod_cidr" {
  type = "string"
  default = "10.42.0.0/16"
}

variable "k8s_service_cidr" {
  type = "string"
  default = "10.96.0.0/16"
}

variable "k8s_api_ip" {
  type = "string"
  default = "10.96.0.1"
}

variable "k8s_version" {
  type = "string"
  default = "1.13.1"
}

variable "openstack_cloud_controller_manager_version" {
  type = "string"
  default = "1.13.0"
}

variable "openstack_token" {
  type = "string"
}

variable "openstack_domain_id" {
  type    = "string"
  default = "default"
}

variable "openstack_tenant_id" {
  type    = "string"
}

variable "openstack_auth_url" {
  type    = "string"
  default = "https://api.r1.nxs.enix.io/v3"
}

variable "openstack_external_network_id" {
  type    = "string"
  default = "<your_external_network_id>" #FIXME
}

variable "openstack_floating_ip_pool" {
  type    = "string"
  default = "Public Floating"
}

variable "openstack_private_network_id" {
  type    = "string"
  default = "<your_admin_network_id>" #FIXME
}

variable "openstack_kubernetes_username" {
  type    = "string"
}

variable "openstack_kubernetes_password" {
  type    = "string"
}