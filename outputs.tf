output "ip_addresses" {
  value = [for v in module.rds : v.ip_address]
}
output "virtual_machine_names" {
  value = [for v in module.rds : v.virtual_machine_name]
  
}