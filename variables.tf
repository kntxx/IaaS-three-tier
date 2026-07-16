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