output "internal_ips" {
  value = "${zipmap(concat(openstack_compute_instance_v2.private_node.*.name, openstack_compute_instance_v2.non_private_node.*.name), concat(openstack_compute_instance_v2.private_node.*.network.0.fixed_ip_v4, openstack_compute_instance_v2.non_private_node.*.network.0.fixed_ip_v4))}"
}

locals {
  private_ips = "${zipmap(openstack_compute_instance_v2.private_node.*.name, openstack_compute_instance_v2.private_node.*.network.1.fixed_ip_v4)}"
  public_ips = "${zipmap(slice(concat(openstack_compute_instance_v2.private_node.*.name, openstack_compute_instance_v2.non_private_node.*.name), 0, length(openstack_compute_floatingip_associate_v2.floating_ip.*.floating_ip)), openstack_compute_floatingip_associate_v2.floating_ip.*.floating_ip)}"
}

output "private_ips" {
  value = "${local.private_ips}"
}

output "public_ips" {
  value = "${local.public_ips}"
}

output "access_ips" {
  value = "${merge(local.public_ips, local.private_ips)}"
}

output "ids" {
  value = "${zipmap(concat(openstack_compute_instance_v2.private_node.*.name, openstack_compute_instance_v2.non_private_node.*.name), concat(openstack_compute_instance_v2.private_node.*.id, openstack_compute_instance_v2.non_private_node.*.id))}"
}