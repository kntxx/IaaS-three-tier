resource "azurerm_virtual_network" "hub_vnet" {
  location            = var.location
  resource_group_name = var.rg_name

  name          = "vnet-hub"
  address_space = var.hub_cidr
}

resource "azurerm_subnet" "snet_hub_appgw" {
  name                = "snet-hub-appgw"
  resource_group_name = var.rg_name

  address_prefixes     = var.snet_hub_appgw_prefix
  virtual_network_name = azurerm_virtual_network.hub_vnet.name

}
resource "azurerm_subnet" "snet_hub_bastion" {
  name                = "AzureBastionSubnet"
  resource_group_name = var.rg_name

  address_prefixes     = var.snet_hub_bastion_prefix
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
}


resource "azurerm_virtual_network" "web_vnet" {
  location            = var.location
  resource_group_name = var.rg_name

  name          = "vnet-web"
  address_space = var.web_cidr
}

resource "azurerm_subnet" "snet_web_compute" {
  name                = "snet-web-compute"
  resource_group_name = var.rg_name

  address_prefixes     = var.snet_web_compute_prefix
  virtual_network_name = azurerm_virtual_network.web_vnet.name
}



resource "azurerm_virtual_network" "app_vnet" {
  location            = var.location
  resource_group_name = var.rg_name

  name          = "vnet-app"
  address_space = var.app_cidr
}

resource "azurerm_subnet" "snet_app_compute" {
  name                = "snet-app-compute"
  resource_group_name = var.rg_name

  address_prefixes     = var.snet_app_compute_prefix
  virtual_network_name = azurerm_virtual_network.app_vnet.name
}

resource "azurerm_subnet" "snet_app_db" {
  name                = "snet-app-data"
  resource_group_name = var.rg_name

  address_prefixes     = var.snet_app_db_prefix
  virtual_network_name = azurerm_virtual_network.app_vnet.name

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


resource "azurerm_public_ip" "pip_web" {
  name                = "pip-nat-web"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_web" {
  name                = "nat-gateway-web"
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "Standard"
}


resource "azurerm_nat_gateway_public_ip_association" "assoc_pip_nat_web" {
  nat_gateway_id       = azurerm_nat_gateway.nat_web.id
  public_ip_address_id = azurerm_public_ip.pip_web.id
}


resource "azurerm_subnet_nat_gateway_association" "assoc_snet_nat_web" {
  nat_gateway_id = azurerm_nat_gateway.nat_web.id
  subnet_id      = azurerm_subnet.snet_web_compute.id
}

resource "azurerm_public_ip" "pip_nat" {
  name                = "pip-nat-app"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_app" {
  name                = "nat-gateway-app"
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "assoc-pip-nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat_app.id
  public_ip_address_id = azurerm_public_ip.pip_nat.id
}

resource "azurerm_subnet_nat_gateway_association" "assoc-snet-nat-app" {
  subnet_id      = azurerm_subnet.snet_app_compute.id
  nat_gateway_id = azurerm_nat_gateway.nat_app.id
}


## peering

#!hub to web
resource "azurerm_virtual_network_peering" "hub_to_web" {
  name                = "peer-hub-to-web"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_vnet.id
}

resource "azurerm_virtual_network_peering" "web_to_hub" {
  name                = "peer-web-to-hub"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.web_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}

#!hub to app
resource "azurerm_virtual_network_peering" "hub_to_app" {
  name                = "peer-hub-to-app"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_vnet.id
}

resource "azurerm_virtual_network_peering" "app_to_hub" {
  name                = "peer-app-to-hub"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub_vnet.id
}

#!web to app
resource "azurerm_virtual_network_peering" "web_to_app" {
  name                = "peer-web-to-app"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.web_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.app_vnet.id
}

resource "azurerm_virtual_network_peering" "app_to_web" {
  name                = "peer-app-to-web"
  resource_group_name = var.rg_name

  virtual_network_name      = azurerm_virtual_network.app_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.web_vnet.id
}

