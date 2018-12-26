output "cluster_name" {
  value = "${var.k8s_cluster_name}"
}

output "internal_ips" {
  value = "${merge(module.masters.internal_ips, module.workers.internal_ips)}"
}

output "private_ips" {
  value = "${merge(module.masters.private_ips, module.workers.private_ips)}"
}

output "public_ips" {
  value = "${merge(module.masters.public_ips, module.workers.public_ips)}"
}

output "access_ips" {
  value = "${merge(module.masters.access_ips, module.workers.access_ips)}"
}