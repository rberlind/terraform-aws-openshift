// Vault provider
// Set VAULT_ADDR and VAULT_TOKEN environment variables
provider "vault" {}

// AWS credentials from Vault
data "vault_aws_access_credentials" "aws_creds" {
  backend = "aws"
  role = "deploy"
}

// Vault Kubernetes Auth Backend
resource "vault_auth_backend" "k8s" {
  type = "kubernetes"
  path = "${var.vault_k8s_auth_path}"
  description = "Vault Auth Backend for OpenShift"
}

//  Setup the core provider information.
provider "aws" {
  access_key = "${data.vault_aws_access_credentials.aws_creds.access_key}"
  secret_key = "${data.vault_aws_access_credentials.aws_creds.secret_key}"
  region  = "${var.region}"
}

//  Create the OpenShift cluster using our module.
module "openshift" {
  source          = "./modules/openshift"
  region          = "${var.region}"
  amisize         = "t2.large"    //  Smallest that meets the min specs for OS
  vpc_cidr        = "10.0.0.0/16"
  subnetaz        = "${var.subnetaz}"
  subnet_cidr     = "10.0.1.0/24"
  key_name        = "openshift"
  public_key_path = "${var.public_key_path}"
}

//  Output some useful variables for quick SSH access etc.
output "master-url" {
  value = "https://${module.openshift.master-public_ip}.xip.io:8443"
}
output "master-public_dns" {
  value = "${module.openshift.master-public_dns}"
}
output "master-public_ip" {
  value = "${module.openshift.master-public_ip}"
}
output "bastion-public_dns" {
  value = "${module.openshift.bastion-public_dns}"
}
output "bastion-public_ip" {
  value = "${module.openshift.bastion-public_ip}"
}
