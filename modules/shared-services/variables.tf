variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_app_id" {
  type = string
}


variable "bastion_subnet_id" {
  type = string
}

variable "admin_object_id" {
  description = "Personal Azure AD object ID for Key Vault access"
  type        = string
}