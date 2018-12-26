resource "openstack_networking_port_v2" "k8s_port" {
  count = "${var.nodes_count}"
  network_id = "${var.internal_network_id}"
  admin_state_up = "true"
  fixed_ip {
    subnet_id = "${var.internal_network_subnet_id}"
  }
  allowed_address_pairs {
    ip_address = "${var.k8s_pod_cidr}"
  }
  allowed_address_pairs {
    ip_address = "${var.k8s_service_cidr}"
  }
  security_group_ids = ["${var.security_group_id}"]
}