data "template_file" "cloud_config" {
  template = "${file(local.cloud_config_template)}"

  vars {
    DOCKER_VERSION = "18.06.1~ce~3-0~ubuntu"
    DOCKER_COMPOSE_VERSION = "1.23.1"
    KUBERNETES_VERSION = "${var.k8s_version}-00"
    STERN_VERSION = "1.10.0"
    # check version here https://github.com/wercker/stern/releases
  }
}

data "template_cloudinit_config" "cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
  }
}