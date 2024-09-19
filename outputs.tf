output "ip_addresses" {
  value = [for v in module.rds : v.ip_address]
}
output "virtual_machine_names" {
  value = [for v in module.rds : v.virtual_machine_name]
  
}

output "generated_aliases_debug" {  
  value = module.windows_remote_desktop_target.generated_aliases_debug
}