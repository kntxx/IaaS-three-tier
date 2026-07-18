resource "azurerm_storage_account" "sa" {
    name                     = "stapptier2026"
    resource_group_name      = var.rg_name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version          = "TLS1_2"
    allow_nested_items_to_be_public = false
    public_network_access_enabled = true

}

resource "azurerm_storage_container" "app_assets" {
  name                  = "app-assets"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}
