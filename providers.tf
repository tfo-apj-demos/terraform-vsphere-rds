terraform {
  required_providers {
    nsxt = {
      source  = "vmware/nsxt"
      version = "3.4"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2"
    }
    ad = {
      source  = "hashicorp/ad"
      version = "~> 0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3"
    }
    boundary = {
      source = "hashicorp/boundary"
      version = "~> 1"
    }
  }
}

provider "boundary" {
  addr  = var.boundary_address
  token = var.boundary_token 
}