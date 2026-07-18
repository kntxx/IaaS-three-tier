resource "azurerm_linux_virtual_machine_scale_set" "vmss_web" {
  name                 = "vmss_web"
  computer_name_prefix = "vmss-web-"
  resource_group_name  = var.rg_name
  location             = var.location
  admin_username       = var.vm_username

  instances                       = 1
  disable_password_authentication = true
  zones                           = ["1", "2", "3"]
  sku                             = "Standard_B2ats_v2"
  upgrade_mode = "Rolling"
  
 rolling_upgrade_policy {
    max_batch_instance_percent              = 50
    max_unhealthy_instance_percent          = 50
    max_unhealthy_upgraded_instance_percent = 50
    pause_time_between_batches              = "PT30S"
  }
  admin_ssh_key {
    username   = var.vm_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "ni-webb"
    primary = true
    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = var.web_subnet_id
      application_gateway_backend_address_pool_ids = [var.appgw_backend_pool_id]
    }
  }

  custom_data = base64encode(
    templatefile("${path.module}/scripts/web-init.sh", {
      internal_lb_ip = var.internal_lb_ip
    })
  )
}
resource "azurerm_virtual_machine_scale_set_extension" "health_web" {
  name                         = "health-extension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss_web.id
  publisher                    = "Microsoft.ManagedServices"
  type                         = "ApplicationHealthLinux"
  type_handler_version         = "2.0"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    protocol    = "http"
    port        = 80
    requestPath = "/"
  })
}
resource "azurerm_monitor_autoscale_setting" "web_autoscale" {
  name                = "autoscale-web"
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss_web.id

  profile {
    name = "default"

    capacity {
      minimum = 1
      default = 1
      maximum = 2  
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss_web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss_web.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
resource "azurerm_linux_virtual_machine_scale_set" "vmss_app" {
  name                            = "vmss_app"
  computer_name_prefix            = "vmss-app-"
  resource_group_name             = var.rg_name
  location                        = var.location
  admin_username                  = var.vm_username
  instances                       = 1
  disable_password_authentication = true
  zones                           = ["1", "2", "3"]
  sku                             = "Standard_B2ats_v2"
  upgrade_mode = "Rolling"
  health_probe_id = var.internal_lb_probe_id
  rolling_upgrade_policy {
    max_batch_instance_percent              = 50
    max_unhealthy_instance_percent          = 50
    max_unhealthy_upgraded_instance_percent = 50
    pause_time_between_batches              = "PT30S"
  }

  admin_ssh_key {
    username   = var.vm_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "ni-app"
    primary = true
    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.app_subnet_id

      load_balancer_backend_address_pool_ids = [var.internal_lb_backendpool_id]
    }
  }

  custom_data = base64encode(
    templatefile("${path.module}/scripts/app-init.sh", {
      db_user      = var.db_admin_user
      db_pass      = var.db_admin_password
      db_fqdn      = var.db_fqdn
      storage_name = var.storage_account_name
      storage_key  = var.storage_access_key
    })
  )
}

resource "azurerm_monitor_autoscale_setting" "app_autoscale" {
  name                = "autoscale-app"
  resource_group_name = var.rg_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss_app.id

  profile {
    name = "default"

    capacity {
      minimum = 1
      default = 1
      maximum = 2   
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss_app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss_app.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_virtual_machine_scale_set_extension" "datadog_web" {
  name                         = "datadog_web"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss_web.id
  publisher                    = "Datadog.Agent"
  type                         = "DatadogLinuxAgent"
  type_handler_version         = "9.0"
  auto_upgrade_minor_version   = true
  settings = jsonencode({
    site = "us5.datadoghq.com"
    tags = ["environment:${var.env}"]
  })
  protected_settings = jsonencode({
    api_key = var.datadog_api_key
  })
}


resource "azurerm_virtual_machine_scale_set_extension" "datadog_app" {
  name                         = "datadog_app"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss_app.id
  publisher                    = "Datadog.Agent"
  type                         = "DatadogLinuxAgent"
  type_handler_version         = "9.0"
  auto_upgrade_minor_version   = true

  settings = jsonencode({
    site = "us5.datadoghq.com"
    tags = ["environment:${var.env}"]
  })
  protected_settings = jsonencode({
    api_key = var.datadog_api_key
  })
}