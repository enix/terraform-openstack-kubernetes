resource "openstack_compute_keypair_v2" "ssh_deploy_key" {
  name       = "${var.k8s_cluster_name} deploy key"
  public_key = "${file(var.ssh_public_key)}"
}

resource "openstack_networking_secgroup_v2" "full_access" {
  name = "${var.k8s_cluster_name} full access"
}

resource "openstack_networking_secgroup_rule_v2" "full_access" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = ""
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.full_access.id}"
}