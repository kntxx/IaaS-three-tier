# ------------------------------------------------------------------------------------------------───
# 1. WEB TIER NSG
# ------------------------------------------------------------------------------------------------───
resource "azurerm_network_security_group" "nsg_web" {
  name                = "nsg-web"
  location            = var.location
  resource_group_name = var.rg_name

  # Allow HTTP/HTTPS from the Application Gateway in the Hub
  security_rule {
    name                       = "Allow-HTTPS-From-AppGW"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefixes    = var.snet_hub_appgw_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Bastion"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range    = "22"
    source_address_prefixes    = var.snet_hub_bastion_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_assoc" {
  subnet_id = azurerm_subnet.snet_web_compute.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

# ------------------------------------------------------------------------------------------------───
# 2. APP TIER NSG
# ------------------------------------------------------------------------------------------------───


resource "azurerm_network_security_group" "nsg_app" {
    name                = "nsg-app"
    location            = var.location
    resource_group_name = var.rg_name

    security_rule {
        name                       = "Allow-API"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range    = "8080"
        source_address_prefixes    = var.snet_web_compute_prefix
        destination_address_prefix = "*"  
    }

    security_rule {
        name                       = "Allow-SSH-Bastion"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range    = "22"
        source_address_prefixes    = var.snet_hub_bastion_prefix
        destination_address_prefix = "*"  
    }
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_assoc" {
  subnet_id = azurerm_subnet.snet_app_compute.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}


# ------------------------------------------------------------------------------------------------───
# 3. DATA TIER NSG (The most locked down)
# ------------------------------------------------------------------------------------------------───

resource "azurerm_network_security_group" "nsg_db" {
    name                = "nsg-db"
    location            = var.location
    resource_group_name = var.rg_name

    security_rule {
        name                       = "Allow-postgresql-from-app"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range    = "5432"
        source_address_prefixes    = var.snet_app_compute_prefix
        destination_address_prefix = "*"  
    }

}

resource "azurerm_subnet_network_security_group_association" "db_nsg_assoc" {
  subnet_id = azurerm_subnet.snet_app_db.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}
