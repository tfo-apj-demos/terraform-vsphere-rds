output "ip_addresses" {
  value = [ for v in module.rds: v.ip_address ]
}