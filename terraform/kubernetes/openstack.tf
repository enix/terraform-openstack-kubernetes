provider "openstack" {
  token       = "${var.openstack_token}"
  tenant_id   = "${var.openstack_tenant_id}"
  domain_id   = "${var.openstack_domain_id}"
  auth_url    = "${var.openstack_auth_url}"
}

resource "openstack_compute_servergroup_v2" "controlplane" {
  name      = "${var.k8s_cluster_name} control plane"
  policies  = ["anti-affinity"]
}

resource "openstack_compute_servergroup_v2" "compute" {
  name      = "${var.k8s_cluster_name} compute"
  policies  = ["anti-affinity"]
}