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
  display_name = "remote-desktop"
  pool_path    = data.nsxt_policy_ip_pool.this.path
}

module "remote_desktop" {
  source  = "app.terraform.io/tfo-apj-demos/virtual-machine/vsphere"
  version = "~> 1.3"

  num_cpus = 4
  memory = 8192

  hostname          = "remote-desktop-server"
  datacenter        = "Datacenter"
  cluster           = "cluster"
  primary_datastore = "vsanDatastore"
  folder_path       = "management"
  networks = {
    "seg-general" : "${nsxt_policy_ip_address_allocation.this.allocation_ip}/22"
  }
  dns_server_list = [
    "172.21.15.150",
    "10.10.0.8"
  ]
  gateway         = "172.21.12.1"
  dns_suffix_list = ["hashicorp.local"]
  disk_0_size = 60

  template = data.hcp_packer_image.this.cloud_image_id
  tags = {}

  join_domain = "hashicorp.local"
  #ad_domain = "hashicorp.local"
  domain_admin_user = "administrator"
  domain_admin_password = var.domain_admin_password
  admin_password = var.domain_admin_password
}

module "boundary_target" {
  source  = "app.terraform.io/tfo-apj-demos/target/boundary"
  version = "~> 0.0"

  hosts = [
    { 
      "hostname" = module.remote_desktop.virtual_machine_name, 
      "address" = module.remote_desktop.ip_address
    }
  ]
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

