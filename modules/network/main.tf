resource "azurerm_virtual_network" "hub_vnet" {
  location = var.location
  resource_group_name = var.rg_name

  name = "vnet-hub"
  address_space = var.hub_cidr
}

resource "azurerm_subnet" "snet_hub_appgw" {
  name = "snet-hub-appgw"
  resource_group_name = var.rg_name
  
  address_prefixes = var.snet_hub_appgw_prefix
  virtual_network_name = azurerm_virtual_network.hub_vnet.name

}
resource "azurerm_subnet" "snet_hub_bastion" {
  name = "AzureBastionSubnet"
  resource_group_name = var.rg_name
  
  address_prefixes = var.snet_hub_bastion_prefix
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}

resource "azurerm_subnet" "snet_hub_shared" {
  name = "snet-hub-shared"
  resource_group_name = var.rg_name
  
  address_prefixes = var.snet_hub_shared_prefix
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}



resource "azurerm_virtual_network" "web_vnet" {
    location = var.location
    resource_group_name = var.rg_name

    name = "vnet-web"
    address_space = var.web_cidr
}

resource "azurerm_subnet" "snet_web_compute" {
  name = "snet-web-compute"
  resource_group_name = var.rg_name

  address_prefixes = var.snet_web_compute_prefix
  virtual_network_name = azurerm_virtual_network.web_vnet.name
}



resource "azurerm_virtual_network" "app_vnet" {
    location = var.location
    resource_group_name = var.rg_name

    name = "vnet-app"
    address_space = var.app_cidr
}

resource "azurerm_subnet" "snet_app_compute" {
  name = "snet-app-compute"
  resource_group_name = var.rg_name
  
  address_prefixes = var.snet_app_compute_prefix
  virtual_network_name = azurerm_virtual_network.app_vnet.name
}

resource "azurerm_subnet" "snet_app_db" {
  name = "snet-app-data"
  resource_group_name = var.rg_name
  
  address_prefixes = var.snet_app_db_prefix
  virtual_network_name = azurerm_virtual_network.app_vnet.name

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


## peering

#!hub to web
resource "azurerm_virtual_network_peering" "hub_to_web" {
  name                      = "peer-hub-to-web"
  resource_group_name       = var.rg_name
  
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_vnet.id
}

resource "azurerm_virtual_network_peering" "web_to_hub" {
  name                      = "peer-web-to-hub"
  resource_group_name       = var.rg_name

  virtual_network_name      = azurerm_virtual_network.web_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id 
}

#!hub to app
resource "azurerm_virtual_network_peering" "hub_to_app" {
  name                      = "peer-hub-to-app"
  resource_group_name       = var.rg_name
  
  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_vnet.id
}

resource "azurerm_virtual_network_peering" "app_to_hub" {
  name                      = "peer-app-to-hub"
  resource_group_name       = var.rg_name

  virtual_network_name      = azurerm_virtual_network.app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id 
}

#!web to app
resource "azurerm_virtual_network_peering" "web_to_app" {
  name                      = "peer-web-to-app"
  resource_group_name       = var.rg_name
  
  virtual_network_name      = azurerm_virtual_network.web_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_vnet.id
}

resource "azurerm_virtual_network_peering" "app_to_web" {
  name                      = "peer-app-to-web"
  resource_group_name       = var.rg_name

  virtual_network_name      = azurerm_virtual_network.app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_vnet.id
}

