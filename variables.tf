variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}



variable "env" {
  type = string
}
variable "datadog_api_key" {
  type      = string
  sensitive = true
}
variable "datadog_app_key" {
  type        = string
  sensitive   = true 
}

variable "admin_object_id" {
  description = "Personal Azure AD object ID for Key Vault access"
  type        = string
}