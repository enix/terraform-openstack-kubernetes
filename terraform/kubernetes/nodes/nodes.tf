resource "openstack_compute_instance_v2" "private_node" {
  count = "${var.nodes_count * var.private_access}"
  name = "${format("%s-%d", var.name_prefix, count.index + 1)}"
  image_name = "${var.operating_system_image}"
  flavor_name = "${var.flavor}"
  key_pair = "${var.ssh_deploy_key_name}"
  user_data = "${data.template_cloudinit_config.cloud_config.rendered}"
  network {
    port = "${openstack_networking_port_v2.k8s_port.*.id[count.index]}"
    access_network = false
  }
  network {
    uuid = "${var.private_network_id}"
    access_network = true
  }
  scheduler_hints {
    group = "${var.scheduler_hints_group_id}"
  }
}

resource "openstack_compute_instance_v2" "non_private_node" {
  count = "${var.nodes_count * (1 - var.private_access)}"
  name = "${format("%s-%d", var.name_prefix, count.index + 1)}"
  image_name = "${var.operating_system_image}"
  flavor_name = "${var.flavor}"
  key_pair = "${var.ssh_deploy_key_name}"
  user_data = "${data.template_cloudinit_config.cloud_config.rendered}"
  network {
    port = "${openstack_networking_port_v2.k8s_port.*.id[count.index]}"
    access_network = false
  }
  scheduler_hints {
    group = "${var.scheduler_hints_group_id}"
  }
}

resource "openstack_networking_floatingip_v2" "floating_ip" {
  count = "${var.nodes_count * var.public_access}"
  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "floating_ip" {
  count = "${var.nodes_count * var.public_access}"
  floating_ip = "${openstack_networking_floatingip_v2.floating_ip.*.address[count.index]}"
  instance_id = "${element(concat(openstack_compute_instance_v2.private_node.*.id, openstack_compute_instance_v2.non_private_node.*.id), count.index)}"
  wait_until_associated = true
}