data "hcp_packer_artifact" "this" {
  bucket_name  = "base-windows-2022"
  channel_name = "latest"
  platform     = "vsphere"
  region       = "Datacenter"
}

data "nsxt_policy_ip_pool" "this" {
  display_name = "10 - gcve-foundations"
}
resource "nsxt_policy_ip_address_allocation" "this" {
  for_each     = toset(var.hostnames)
  display_name = "remote-desktop"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

module "rds" {
  for_each = toset(var.hostnames)
  source   = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 1.4"

  num_cpus = 4
  memory   = 8192

  hostname          = each.value
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "Demo Workloads"
  networks = {
    "seg-general" : "${nsxt_policy_ip_address_allocation.this["${each.value}"].allocation_ip}/22"
  }
  dns_server_list = [
    "172.21.15.150",
    "10.10.0.8"
  ]
  gateway         = "172.21.12.1"
  dns_suffix_list = ["hashicorp.local"]
  disk_0_size     = 100

  template = data.hcp_packer_artifact.this.external_identifier

  admin_password        = var.admin_password
  ad_domain             = var.ad_domain
  domain_admin_user     = var.domain_admin_user
  domain_admin_password = var.domain_admin_password
}

resource "ad_computer" "this" {
  for_each = toset(var.hostnames)

  name        = each.value # using each.value to get the current hostname
  pre2kname   = each.value # same here
  container   = "OU=Terraform Managed Computers,DC=hashicorp,DC=local"
  description = "Terraform Managed Windows Computer"
}

module "domain-name-system-management" {
  source  = "app.terraform.io/tfo-apj-demos/domain-name-system-management/dns"
  version = "~> 1.0"

  a_records = [for hostname in var.hostnames : {
    name      = hostname
    addresses = [module.rds[hostname].ip_address]
  }]
}

resource "vault_token" "this" {
  no_parent = true
  period    = "24h"
  policies = [
    "ldap_reader",
    "revoke_lease"
  ]
  metadata = {
    "purpose" = "service-account"
  }
}

# module "windows_remote_desktop_target" {
#   source  = "app.terraform.io/tfo-apj-demos/target/boundary"
#   version = "~> 2"

#   project_name           = "gcve_admins"
#   hostname_prefix        = "On-Prem Windows Remote Desktop Server"
#   credential_store_token = vault_token.this.client_token
#   vault_address          = "https://vault.hashicorp.local:8200"

#   hosts = [for host in module.rds : {
#     fqdn = "${host.virtual_machine_name}.hashicorp.local"
#   }]

#   services = [{
#     type             = "tcp"
#     port             = 3389
#     use_existing_creds = false
#     use_vault_creds    = true
#     credential_path    = "ldap/creds/vault_ldap_dynamic_demo_role"
#   }]
# }

module "windows_remote_desktop_target" {
  source               = "github.com/tfo-apj-demos/terraform-boundary-target-refactored"
  
  project_name         = "gcve_admins"
  target_name          = "Windows Remote Desktop Server"
  hosts                = ["rds-01.hashicorp.local"]
  port                 = 3389
  target_type          = "tcp"
  
  # Vault credential configurations
  use_credentials      = true
  credential_store_token = vault_token.this.client_token
  vault_address        = "https://vault.hashicorp.local:8200"
  credential_source    = "vault"
  credential_path      = "ldap/creds/vault_ldap_dynamic_demo_role"
  
  # Alias name matching one of the Windows servers or a primary address for access
  alias_name           = "rds-01.hashicorp.local"
}