resource "null_resource" "k8s_master_cloud_init_provisioner" {
  count = "${var.k8s_master_nodes_count}"
  triggers {
    master_node = "${element(values(module.masters.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), count.index)}"
  }
  provisioner "remote-exec" {
    # simple command to make terraform wait for host to be up
    script = "${local.wait_for_cloud_init_script}"
  }
}

resource "null_resource" "k8s_master_configuration_provisioner" {
  depends_on = ["null_resource.k8s_master_cloud_init_provisioner"]
  count = "${var.k8s_master_nodes_count}"
  triggers {
    master_nodes = "${join(",",values(module.masters.ids))}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), count.index)}"
  }
  provisioner "file" {
    content = "${element(data.template_file.kubeadm_config.*.rendered, count.index)}"
    destination = "${local.kubeadm_config_file}"
  }
  provisioner "file" {
    content = "${element(data.template_file.kubeadm_config_etcd.*.rendered, count.index)}"
    destination = "${local.kubeadm_config_etcd_file}"
  }
  provisioner "file" {
    content = "${data.template_file.api_loadbalancer.rendered}"
    destination = "${local.docker_compose_api_loadbalancer_file}"
  }
  provisioner "file" {
    content = "${element(data.template_file.etcd.*.rendered, count.index)}"
    destination = "${local.docker_compose_etcd_file}"
  }
  provisioner "file" {
    content = "${data.template_file.cloud_provider_configuration.rendered}"
    destination = "${local.cloud_provider_configuration_file}"
  }
  provisioner "file" {
    content = "${data.template_file.cloud_controller_manager.rendered}"
    destination = "${local.cloud_controller_manager_file}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      # "sudo mkdir /etc/kubernetes || true", #created by ubuntu packages during cloud init phase
      "sudo mv ${local.kubeadm_config_file} ${local.kubeadm_config_etcd_file} ${local.docker_compose_api_loadbalancer_file} ${local.docker_compose_etcd_file} ${local.cloud_provider_configuration_file} /etc/kubernetes/",
      "sudo mv ${local.cloud_controller_manager_file} /etc/kubernetes/manifests/",
      "sudo chown -R root:root /etc/kubernetes"
      ]
  }
}

resource "null_resource" "k8s_master_api_loadbalancer" {
  depends_on = ["null_resource.k8s_master_configuration_provisioner"]
  count = "${var.k8s_master_nodes_count}"
  triggers {
    master_node = "${element(values(module.masters.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), count.index)}"
  }
  provisioner "remote-exec" {
    inline = [
      "docker-compose -p api-loadbalancer -f /etc/kubernetes/${local.docker_compose_api_loadbalancer_file} up -d --quiet-pull"
      ]
  }
}

resource "null_resource" "k8s_master_ca_generator" {
  depends_on = ["null_resource.k8s_master_configuration_provisioner"]
  count = "${var.k8s_master_nodes_count > 0 ? 1 : 0}"
  triggers {
    master_node = "${element(values(module.masters.ids), 0)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo kubeadm init phase certs all --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase certs etcd-ca --config=/etc/kubernetes/${local.kubeadm_config_etcd_file}"
      ]
  }
}

resource "null_resource" "k8s_master_ca_replicator" {
  depends_on = ["null_resource.k8s_master_ca_generator"]
  count = "${max(0, var.k8s_master_nodes_count - 1)}"
  triggers {
    init_master_node = "${element(values(module.masters.ids), 0)}"
    other_master_node = "${element(values(module.masters.ids), count.index + 1)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo tar -cz /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/ca.key /etc/kubernetes/pki/apiserver-kubelet-client.crt /etc/kubernetes/pki/apiserver-kubelet-client.key /etc/kubernetes/pki/sa.key /etc/kubernetes/pki/sa.pub /etc/kubernetes/pki/front-proxy-ca.crt /etc/kubernetes/pki/front-proxy-ca.key /etc/kubernetes/pki/front-proxy-client.crt /etc/kubernetes/pki/front-proxy-client.key /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.key | ssh -o StrictHostKeyChecking=no ubuntu@${element(values(module.masters.internal_ips), count.index + 1)} sudo tar -C / -xz"
      ]
  }
}


resource "null_resource" "k8s_master_etcd_provisioner" {
  depends_on = ["null_resource.k8s_master_ca_replicator", "null_resource.k8s_master_ca_generator"]
  # generator is required as ca_replicator might be empty and therefore unlock to early
  count = "${var.k8s_master_nodes_count}"
  triggers {
    master_node = "${element(values(module.masters.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), count.index)}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo mkdir /var/lib/etcd",
      "sudo kubeadm init phase certs etcd-server --config=/etc/kubernetes/${local.kubeadm_config_etcd_file}",
      "sudo kubeadm init phase certs etcd-peer --config=/etc/kubernetes/${local.kubeadm_config_etcd_file}",
      "sudo kubeadm init phase certs etcd-healthcheck-client --config=/etc/kubernetes/${local.kubeadm_config_etcd_file}",
      "sudo kubeadm init phase certs apiserver-etcd-client --config=/etc/kubernetes/${local.kubeadm_config_etcd_file}",
      "docker-compose -p etcd-cluster -f /etc/kubernetes/${local.docker_compose_etcd_file} up -d --quiet-pull"
      ]
  }
}

resource "null_resource" "k8s_master_etcd_ready" {
  depends_on = ["null_resource.k8s_master_etcd_provisioner"]
  count = "${var.k8s_master_nodes_count > 0 ? 1 : 0}"
  triggers {
    master_node = "${element(values(module.masters.ids), 0)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo curl -sL --output - --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/apiserver-etcd-client.crt --key /etc/kubernetes/pki/apiserver-etcd-client.key https://127.0.0.1:2379/health | jq -e '.health | test(\"true\")'"
      ]
  }
}

resource "null_resource" "k8s_ha_control_plane_ready" {
  depends_on = ["null_resource.k8s_master_etcd_ready", "null_resource.k8s_master_api_loadbalancer"]
  count = "${var.k8s_master_nodes_count}"
  triggers {
    master_node = "${element(values(module.masters.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), count.index)}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo kubeadm init phase certs apiserver --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase kubeconfig all --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "mkdir .kube || true; sudo cat /etc/kubernetes/admin.conf > .kube/config",
      "sudo kubeadm init phase kubelet-start --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase control-plane all --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "until kubectl get nodes; do sleep 3; done",
      # "sudo kubeadm alpha phase kubelet config annotate-cri --config=/etc/kubernetes/${local.kubeadm_config_file}",
      "sudo kubeadm init phase mark-control-plane --config=/etc/kubernetes/${local.kubeadm_config_file}"
      ]
  }
}