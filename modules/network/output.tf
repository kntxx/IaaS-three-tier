output "snet_web_id" {
  value = azurerm_subnet.snet_web_compute.id
}

output "snet_app_comp_id" {
  value = azurerm_subnet.snet_app_compute.id
}

output "snet_app_db_id" {
  value = azurerm_subnet.snet_app_db.id
}

output "vnet_app_id" {
  value = azurerm_virtual_network.app_vnet.id
}

output "vnet_web_id" {
  value = azurerm_virtual_network.web_vnet.id
}

output "snet_bastion_id" {
  value = azurerm_subnet.snet_hub_bastion.id
}

output "snet_hub_appgw_id" {
  value = azurerm_subnet.snet_hub_appgw.id
}