resource "azurerm_storage_account" "sa" {
    name                     = "stapptier2026"
    resource_group_name      = var.rg_name
    location                 = var.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    min_tls_version          = "TLS1_2"
    allow_nested_items_to_be_public = false
    public_network_access_enabled = false
}

resource "azurerm_storage_container" "app_assets" {
  name                  = "app-assets"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_link" {
  name                  = "link-blob-dns-to-app-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = var.vnet_app_id
}

resource "azurerm_private_endpoint" "storage_pe" {
  name                = "pe-storage-blob"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.app_subnet_id

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns.id]
  }
}