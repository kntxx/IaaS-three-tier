resource "random_string" "db_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_postgresql_flexible_server" "postgres" {
  name                = "psql-app-db-${random_string.db_suffix.result}"
  resource_group_name = var.rg_name
  location            = var.location
  version             = "14"

  administrator_login    = var.admin_user
  administrator_password = var.admin_password

  backup_retention_days         = 7
  public_network_access_enabled = false
  delegated_subnet_id           = var.snet_db_id
  private_dns_zone_id           = var.private_dns_zone_id

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  lifecycle {
    ignore_changes = [
      zone,
      high_availability[0].standby_availability_zone
    ]
  }

}