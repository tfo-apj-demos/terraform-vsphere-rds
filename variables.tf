variable "boundary_address" {
  type = string
}

variable "boundary_token" {
  type = string
}

variable "hostnames" {
  type    = list(string)
  default = ["rds-01"]
}

variable "ad_domain" {
  type = string
}

variable "domain_admin_user" {
  type      = string
  sensitive = true
  default   = ""
}

variable "domain_admin_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "vault_address" {
  type    = string
  default = "https://vault.hashicorp.local:8200"
}