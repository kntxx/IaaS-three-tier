variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_username" {
  type = string
}

variable "web_subnet_id" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "admin_ssh_public_key" {
  type = string
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "appgw_backend_pool_id" {
  type = string
}

variable "internal_lb_backendpool_id" {
  type = string
}

variable "internal_lb_ip" {
  type = string
}


variable "db_admin_user" {
  type = string
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}

variable "db_fqdn" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_access_key" {
  type      = string
  sensitive = true
}