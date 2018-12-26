data "template_file" "kubeadm_config" {
  count = "${var.k8s_master_nodes_count}"
  template = "${file(local.kubeadm_config_template)}"

  vars {
    K8S_VERSION = "v${var.k8s_version}"
    K8S_CONTROLPLANE_ENDPOINT = "127.0.0.1"
    K8S_INTERNAL_ADDRESS = "${element(values(module.masters.internal_ips), count.index)}"
    K8S_DOMAIN = "${replace(var.k8s_cluster_name, "_", "-")}"
    K8S_POD_SUBNET = "${var.k8s_pod_cidr}"
    K8S_SERVICE_SUBNET = "${var.k8s_service_cidr}"
    K8S_API_SANS = "[\"${element(values(module.masters.access_ips), count.index)}\"]"
    ETCD_EXTERNAL_ENDPOINTS = "[${join(",", formatlist("\"https://%s:2379\"", values(module.masters.internal_ips)))}]"
  }
}

data "template_file" "kubeadm_config_etcd" {
  count = "${var.k8s_master_nodes_count}"
  template = "${file(local.kubeadm_config_etcd_template)}"

  vars {
    ETCD_INITIAL_CLUSTER = "${join(",", formatlist("%s=https://%s:2380", keys(module.masters.internal_ips), values(module.masters.internal_ips)))}"
    ETCD_INITIAL_CLUSTER_STATE = "${count.index == 0 ? "new" : "existing"}"
    ETCD_PEER_NAME = "${element(keys(module.masters.internal_ips), count.index)}"
    ETCD_PEER_IP = "${element(values(module.masters.internal_ips), count.index)}"
  }
}

data "template_file" "api_loadbalancer" {
  template = "${file(local.docker_compose_api_loadbalancer_template)}"

  vars {
    K8S_MASTERS_IPS = "${join(" ", values(module.masters.internal_ips))}"
  }
}

data "template_file" "etcd" {
  count = "${var.k8s_master_nodes_count}"
  template = "${file(local.docker_compose_etcd_template)}"

  vars {
    ETCD_VERSION = "v3.2.25"
    ETCD_INITIAL_CLUSTER = "${join(",", formatlist("%s=https://%s:2380", keys(module.masters.internal_ips), values(module.masters.internal_ips)))}"
    ETCD_INITIAL_CLUSTER_STATE = "new"
    ETCD_INITIAL_CLUSTER_TOKEN = "etcd-cluster-${replace(var.k8s_cluster_name, "_", "-")}"
    ETCD_PEER_NAME = "${element(keys(module.masters.internal_ips), count.index)}"
    ETCD_PEER_IP = "${element(values(module.masters.internal_ips), count.index)}"
  }
}

data "template_file" "flannel" {
  template = "${file(local.flannel_template)}"

  vars {
    K8S_POD_SUBNET = "${var.k8s_pod_cidr}"
  }
}

data "template_file" "kuberouter" {
  template = "${file(local.kuberouter_template)}"

  vars {
    KUBEROUTER_VERSION = "v0.2.0"
    K8S_CONTROLPLANE_ENDPOINT = "127.0.0.1"
    K8S_POD_SUBNET = "${var.k8s_pod_cidr}"
  }
}

data "template_file" "cloud_controller_manager" {
  template = "${file(local.cloud_controller_manager_template)}"

  vars {
    K8S_CONTROLPLANE_ENDPOINT = "127.0.0.1"
    OPENSTACK_CLOUD_CONTROLLER_MANAGER_VERSION = "${var.openstack_cloud_controller_manager_version}"
  }
}

data "template_file" "cloud_provider_configuration" {
  template = "${file(local.cloud_provider_configuration_template)}"

  vars {
    OPENSTACK_KUBERNETES_USERNAME = "${var.openstack_kubernetes_username}"
    OPENSTACK_KUBERNETES_PASSWORD = "${var.openstack_kubernetes_password}"
    OPENSTACK_AUTH_URL = "${var.openstack_auth_url}"
    OPENSTACK_TENANT_ID = "${var.openstack_tenant_id}"
    OPENSTACK_DOMAIN_ID = "${var.openstack_domain_id}"
    OPENSTACK_LOADBALANCER_SUBNET_ID = "${openstack_networking_subnet_v2.internal.id}"
    OPENSTACK_LOADBALANCER_FLOATING_NETWORK_ID = "${var.openstack_external_network_id}"
  }
}