resource "null_resource" "k8s_worker_cloud_init_provisioner" {
  count = "${var.k8s_worker_nodes_count}"
  triggers {
    worker_node = "${element(values(module.workers.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.workers.internal_ips), count.index)}"
    bastion_host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    # simple command to make terraform wait for host to be up
    script = "${local.wait_for_cloud_init_script}"
  }
}

resource "null_resource" "k8s_worker_configuration_provisioner" {
  depends_on = ["null_resource.k8s_worker_cloud_init_provisioner"]
  count = "${var.k8s_worker_nodes_count}"
  triggers {
    master_nodes = "${join(",",values(module.masters.ids))}"
    worker_node = "${element(values(module.workers.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.workers.internal_ips), count.index)}"
    bastion_host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "file" {
    content = "${data.template_file.api_loadbalancer.rendered}"
    destination = "${local.docker_compose_api_loadbalancer_file}"
  }
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo mkdir /etc/kubernetes || true",
      "sudo mv ${local.docker_compose_api_loadbalancer_file} /etc/kubernetes/",
      "sudo chown -R root:root /etc/kubernetes"
      ]
  }
}

resource "null_resource" "k8s_worker_api_loadbalancer" {
  depends_on = ["null_resource.k8s_worker_configuration_provisioner"]
  count = "${var.k8s_worker_nodes_count}"
  triggers {
    master_nodes = "${join(",",values(module.masters.ids))}"
    worker_node = "${element(values(module.workers.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.workers.internal_ips), count.index)}"
    bastion_host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    inline = [
      "docker-compose -p api-loadbalancer -f /etc/kubernetes/${local.docker_compose_api_loadbalancer_file} up -d --quiet-pull"
      ]
  }
}

resource "null_resource" "k8s_kubeadm_join" {
  count = "${var.k8s_worker_nodes_count}"
  depends_on = ["null_resource.k8s_live_configuration", "null_resource.k8s_worker_api_loadbalancer"]
  triggers {
    worker_node = "${element(values(module.workers.ids), count.index)}"
  }
  connection {
    user = "ubuntu"
    host = "${element(values(module.masters.access_ips), 0)}"
  }
  provisioner "remote-exec" {
    inline = [
      "ssh -o StrictHostKeyChecking=no ${element(values(module.workers.internal_ips), count.index)} sudo `sudo kubeadm token create --print-join-command`",
      "until kubectl label node ${element(keys(module.workers.internal_ips), count.index)} node-role.kubernetes.io/worker=worker; do sleep 2; done"
      ]
  }
}