data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                      = "kv-iaas-shared-01"
  location                  = var.location
  resource_group_name       = var.rg_name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled  = false
  sku_name                  = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Purge"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.admin_object_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "vm_private_key" {
  name         = "vm-ssh-private-key"
  value        = tls_private_key.vm_ssh_key.private_key_pem
  key_vault_id = azurerm_key_vault.kv.id
  
  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.rg_name
}

# Generate a secure 20-character password
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "azurerm_key_vault_secret" "db_password_secret" {
  name         = "postgres-admin-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_app_link" {
  name                  = "link-dns-to-app-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = var.vnet_app_id
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-bastion"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 2. The Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-hub"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}