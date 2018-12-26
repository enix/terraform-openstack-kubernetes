variable "openstack_token" {
  type = "string"
}

variable "openstack_kubernetes_username" {
  type = "string"
}

variable "openstack_kubernetes_password" {
  type = "string"
}

variable "ssh_public_key" {
  type = "string"
  default = "~/.ssh/k8s.nxs.pub"
}

module "kubernetes" {
	source                          = "./terraform/kubernetes"
  k8s_cluster_name                = "k8s-nxs"
  k8s_worker_nodes_count          = 3
  k8s_master_nodes_count          = 3
  k8s_master_private_access       = 1
  openstack_token                 = "${var.openstack_token}"
  openstack_tenant_id             = "<your_tenant_id>"
  openstack_kubernetes_username   = "${var.openstack_kubernetes_username}"
  openstack_kubernetes_password   = "${var.openstack_kubernetes_password}"
  ssh_public_key                  = "${var.ssh_public_key}"
}

output "k8s_cluster_name" {
  value = "${module.kubernetes.cluster_name}"
}

output "k8s_internal_ips" {
  value = "${module.kubernetes.internal_ips}"
}

output "k8s_private_ips" {
  value = "${module.kubernetes.private_ips}"
}

output "k8s_public_ips" {
  value = "${module.kubernetes.public_ips}"
}

output "k8s_access_ips" {
  value = "${module.kubernetes.access_ips}"
}