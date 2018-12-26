resource "openstack_networking_network_v2" "internal" {
  name = "${var.k8s_cluster_name} network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "internal" {
  name = "${var.k8s_cluster_name} subnet"
  network_id = "${openstack_networking_network_v2.internal.id}"
  cidr = "${var.openstack_internal_network_cidr}"
  ip_version = 4
  dns_nameservers = ["1.1.1.1", "1.0.0.1"]
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.k8s_cluster_name} router"
  external_network_id = "${var.openstack_external_network_id}"
}

resource "openstack_networking_router_interface_v2" "router_internal" {
  router_id = "${openstack_networking_router_v2.router.id}"
  subnet_id = "${openstack_networking_subnet_v2.internal.id}"
}