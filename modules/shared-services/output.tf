output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "db_admin_password" {
  value     = random_password.db_password.result
  sensitive = true 
}

output "postgres_dns_zone_id" {
  value = azurerm_private_dns_zone.postgres_dns.id
}

output "vm_public_key" {
  value = tls_private_key.vm_ssh_key.public_key_openssh
  sensitive = true
}


output "bastion_subnet_id" {
  value = azurerm_bastion_host.bastion.id
}

