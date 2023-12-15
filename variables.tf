variable "boundary_address" {
  type = string
}

variable "boundary_token" {
  type = string
}

variable "domain_admin_password" {
  type = string
}

variable "domain_admin_user" {
  type = string
}

variable "ad_domain" {
  type = string
}

variable "hostnames" {
  type = list(string)
  default = [ "rds-01" ]
}