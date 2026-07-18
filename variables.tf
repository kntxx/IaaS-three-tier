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
  type        = string
}

variable "pipeline_runner_ip" {
  type        = string
  default = "0.0.0.0"
}