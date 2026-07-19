resource "azurerm_public_ip" "pip_appgw" {
  name                = "pip-appgw"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

}


resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-web"
  resource_group_name = var.rg_name
  location            = var.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }



  autoscale_configuration {
    min_capacity = 2
    max_capacity = 5
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.pip_appgw.id
  }

  backend_address_pool {
    name = "web-backend-pool"
  }

  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "http-settings"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "probe-web-health"
  }

  probe {
    name                 = "probe-web-health"
    protocol             = "Http"
    path                 = "/"
    interval             = 30
    timeout              = 20
    unhealthy_threshold  = 3

    match {
      status_code = ["200-399"]
    }
  }
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule-http"
    rule_type                  = "Basic"
    http_listener_name         = "listener-http"
    backend_address_pool_name  = "web-backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }
}


resource "azurerm_lb" "internal_lb" {
  name                = "lb-internal"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "private-frontend-ip"
    subnet_id                     = var.snet_app_id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "app-backend-pool"
}

resource "azurerm_lb_probe" "app_probe" {
  loadbalancer_id = azurerm_lb.internal_lb.id
  name            = "probe-api-8080"
  port            = 8080
  protocol        = "Tcp"
}

resource "azurerm_lb_rule" "app_lb_rule" {
  loadbalancer_id                = azurerm_lb.internal_lb.id
  name                           = "rule-api-8080"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "private-frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_probe.id
}