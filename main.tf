terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-devOps-shared"
    storage_account_name = "staccounttffstates01"
    container_name       = "tfstate"
    key                  = "threetier.prod.tfstate"
  }

}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.us5.datadoghq.com/"
}
provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

module "network" {
  source = "./modules/network"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  hub_cidr                = ["10.0.0.0/16"]
  snet_hub_appgw_prefix   = ["10.0.4.0/24"]
  snet_hub_bastion_prefix = ["10.0.5.0/24"]
  snet_hub_shared_prefix  = ["10.0.6.0/24"]

  web_cidr                = ["10.1.0.0/16"]
  snet_web_compute_prefix = ["10.1.4.0/24"]

  app_cidr                = ["10.2.0.0/16"]
  snet_app_compute_prefix = ["10.2.4.0/24"]
  snet_app_db_prefix      = ["10.2.5.0/24"]
}

module "shared_services" {
  source = "./modules/shared-services"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  vnet_app_id       = module.network.vnet_app_id
  bastion_subnet_id = module.network.snet_bastion_id
}


module "compute" {
  source = "./modules/compute"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  vm_username                = "linuxadmin"
  app_subnet_id              = module.network.snet_app_comp_id
  web_subnet_id              = module.network.snet_web_id
  admin_ssh_public_key       = module.shared_services.vm_public_key
  datadog_api_key            = var.datadog_api_key
  appgw_backend_pool_id      = module.loadbalancers.appgw_backend_pool_id
  internal_lb_backendpool_id = module.loadbalancers.internal_lb_backendpool_id
  internal_lb_ip             = module.loadbalancers.internal_lb_ip

  db_admin_user     = "dbuser"
  db_admin_password = module.shared_services.db_admin_password

  db_fqdn = module.database.postgres_fqdn

  storage_access_key   = module.storage.storage_access_key
  storage_account_name = module.storage.storage_account_name
}


module "loadbalancers" {
  source = "./modules/loadbalancers"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  appgw_subnet_id = module.network.snet_hub_appgw_id

  snet_app_id = module.network.snet_app_comp_id
}

module "database" {
  source = "./modules/database"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  admin_user     = "dbuser"
  admin_password = module.shared_services.db_admin_password

  snet_db_id          = module.network.snet_app_db_id
  private_dns_zone_id = module.shared_services.postgres_dns_zone_id
}


module "storage" {
  source = "./modules/storage"

  rg_name  = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
}

module "monitoring" {
  source = "./modules/monitoring"


  web_vmss_id   = module.compute.web_vmss_id
  app_vmss_id = module.compute.app_vmss_id
  postgres_name = module.database.postgres_server_name
  env           = var.env
}