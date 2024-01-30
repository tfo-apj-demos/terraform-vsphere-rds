data "hcp_packer_image" "this" {
  bucket_name    = "base-windows-2022"
  channel        = "latest"
  cloud_provider = "vsphere"
  region         = "Datacenter"
}

data "nsxt_policy_ip_pool" "this" {
  display_name = "10 - gcve-foundations"
}
resource "nsxt_policy_ip_address_allocation" "this" {
  for_each = toset(var.hostnames)
  display_name = "remote-desktop"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

module "rds" {
    for_each = toset(var.hostnames)
    source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
    version = "1.3.5"
    
    num_cpus = 4
    memory = 8192

    hostname = each.value
    cluster = "cluster"
    datacenter = "Datacenter"
    folder_path = "management"
    primary_datastore = "vsanDatastore"
    networks = {
      "seg-general":"${nsxt_policy_ip_address_allocation.this["${each.value}"].allocation_ip}/22"
    }
    dns_server_list = [
      "172.21.15.150",
      "10.10.0.8"
    ]
    gateway = "172.21.12.1"
    dns_suffix_list = ["hashicorp.local"]
    disk_0_size = 60

    template = data.hcp_packer_image.this.cloud_image_id
        
    admin_password        = var.admin_password
    ad_domain             = var.ad_domain
    domain_admin_user     = var.domain_admin_user
    domain_admin_password = var.domain_admin_password
}

resource "ad_computer" "this" {
  for_each = toset(var.hostnames)

  name        = each.value  # using each.value to get the current hostname
  pre2kname   = each.value  # same here
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


module "boundary_target" {
  source  = "app.terraform.io/tfo-apj-demos/target/boundary"
  version = "~> 0.0"

  hosts = [ for host in module.rds: {
    "hostname" = host.virtual_machine_name
    "address" = host.ip_address
  }]

  services = [
    { 
      name = "rdp",
      type = "tcp",
      port = "3389"
    }
  ]
  project_name = "grantorchard"
  host_catalog_id = "hcst_7B2FWBRqb0"
  hostname_prefix = "remote-desktop"
  injected_credential_library_ids = []
}