output "appgw_backend_pool_id" {
  value = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id
}


output "internal_lb_backendpool_id" {
  value = azurerm_lb_backend_address_pool.app_backend_pool.id
}

output "internal_lb_ip" {
  value = azurerm_lb.internal_lb.private_ip_address
}