provider "openstack" {
  token       = "${var.openstack_token}"
  tenant_id   = "${var.openstack_tenant_id}"
  domain_id   = "${var.openstack_domain_id}"
  auth_url    = "${var.openstack_auth_url}"
}