This is a terraform plan which builds a kubernetes cluster over openstack.

It is supposed to be maintanable through either a Enix's admin **private** network or a **public** network.

# FAQ
## Terraform plan waits for ever while provisionning
You might have forgotten to load your private key with `ssh-add`

## How do I get an openstack token
You might generate your openstack_token through
`openstack --os-auth-url=https://api.r1.nxs.enix.io/v3 --os-identity-api-version=3 --os-username=<user> --os-user-domain-name=Default --os-project-name=<tenant> token issue`
and then export it
`export TF_VAR_openstack_token=<token>`

# Security considerations
In order to avoid any clear text password or private key in the terraform state,
this plan relies on **openstack_token** rather than openstack_username and openstack_password
it also relies on the private key being loaded in your **ssh-agent**

# Typical plan to use this module
```
variable "openstack_token" {
  type = "string"
}

variable "ssh_public_key" {
  type = "string"
  default = "~/.ssh/k8s.nxs.pub"
}

module "kubernetes" {
  source                          = "./terraform/kubernetes"
  k8s_cluster_name                = "<cluster_name>"
  k8s_worker_nodes_count          = 1
  k8s_master_nodes_count          = 3
  k8s_master_public_access        = 1
  openstack_token                 = "${var.openstack_token}"
  openstack_tenant                = "<tenant>"
  ssh_public_key                  = "${var.ssh_public_key}"
  #k8s_master_private_access
  #k8s_master_flavor
  #k8s_worker_flavor
}

output "k8s_cluster_name" {
  value = "${module.kubernetes.cluster_name}"
}

output "k8s_internal_ips" {
  value = "${module.kubernetes.internal_ips}"
}

output "k8s_private_ips" {
  value = "${module.kubernetes.private_ips}"
}

output "k8s_public_ips" {
  value = "${module.kubernetes.public_ips}"
}

output "k8s_access_ips" {
  value = "${module.kubernetes.access_ips}"
}
```