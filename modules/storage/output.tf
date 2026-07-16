output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.sa.primary_blob_endpoint
}

output "storage_access_key" {
  value     = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}