resource "null_resource" "k8s_live_configuration" {
  depends_on = ["null_resource.k8s_ha_control_plane_ready"]
  count = "${var.k8s_master_nodes_count > 0 ? 1 : 0}"
  triggers {
    master_node = "${element(values(module.masters.ids), 0)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "file" {
    source = "${local.kubeadm_nokubeproxy_patch_src}"
    destination = "${local.kubeadm_nokubeproxy_patch_file}"
  }
  provisioner "file" {
    source = "${local.cloud_controller_manager_clusterrolebinding_src}"
    destination = "${local.cloud_controller_manager_clusterrolebinding_file}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      # "sudo kubeadm alpha phase kubelet config upload --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase bootstrap-token --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase upload-config all --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase addon coredns --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "kubectl apply -f ${local.kubeadm_nokubeproxy_patch_file}",
      "kubectl apply -f ${local.cloud_controller_manager_clusterrolebinding_file}"
      ]
  }
}

resource "null_resource" "k8s_network_kuberouter" {
  depends_on = ["null_resource.k8s_live_configuration"]
  count = "${var.k8s_master_nodes_count > 0 ? 1 : 0}"
  triggers {
    master_node = "${element(values(module.masters.ids), 0)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "file" {
    content = "${data.template_file.kuberouter.rendered}"
    destination = "${local.kuberouter_file}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo mv ${local.kuberouter_file} /etc/kubernetes/",
      "sudo chown -R root:root /etc/kubernetes/${local.kuberouter_file}",
      "kubectl apply -f /etc/kubernetes/${local.kuberouter_file}"
      ]
  }
}

# resource "null_resource" "k8s_network_flannel" {
#   depends_on = ["null_resource.k8s_live_configuration"]
#   count = "${var.k8s_master_nodes_count > 0 ? 1 : 0}"
#   connection {
#     user = "ubuntu"
#     host = "${element(values(module.masters.access_ips), 0)}"
#   }
#   provisioner "file" {
#     content = "${data.template_file.kube_flannel.rendered}"
#     destination = "${local.kube_flannel_file}"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "set -e",
#       "sudo mv ${local.kube_flannel_file} /etc/kubernetes/",
#       "sudo chown -R root:root /etc/kubernetes/${local.kube_flannel_file}",
#       "kubectl apply -f /etc/kubernetes/${local.kube_flannel_file}"
#       ]
#   }
# }