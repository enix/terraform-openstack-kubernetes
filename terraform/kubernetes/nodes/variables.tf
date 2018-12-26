variable "name_prefix" {
  type = "string"
  default = "node"
}

variable "nodes_count" {
  type = "string"
  default = 0
}

variable "private_access" {
  type = "string"
  default = 0
}

variable "private_network_id" {
  type = "string"
  default = ""
}

variable "internal_network_id" {
  type = "string"
}

variable "internal_network_cidr" {
  type = "string"
}

variable "internal_network_subnet_id" {
  type = "string"
}

variable "k8s_pod_cidr" {
  type = "string"
}

variable "k8s_service_cidr" {
  type = "string"
}

variable "k8s_version" {
  type = "string"
}

variable "public_access" {
  type = "string"
  default = 0
}

variable "flavor" {
  type = "string"
  default = "GP1.S"
}

variable "operating_system_image" {
  type = "string"
  default = "Ubuntu 18.04.1 (Bionic Beaver)"
}

variable "ssh_deploy_key_name" {
  type = "string"
}

variable "scheduler_hints_group_id" {
  type = "string"
}

variable "floating_ip_pool" {
  type = "string"
  default = ""
}

variable "security_group_id" {
  type = "string"
  default = ""
}

variable "openstack_token" {
  type = "string"
}

variable "openstack_tenant_id" {
  type = "string"
}

variable "openstack_domain_id" {
  type = "string"
}

variable "openstack_auth_url" {
  type = "string"
}