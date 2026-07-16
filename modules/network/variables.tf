variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}


variable "hub_cidr" {
  type = list(string)
}

variable "snet_hub_appgw_prefix" {
  type = list(string)
}
variable "snet_hub_bastion_prefix" {
  type = list(string)
}
variable "snet_hub_shared_prefix" {
  type = list(string)
}


variable "web_cidr" {
  type = list(string)
}

variable "snet_web_compute_prefix" {
  type = list(string)
}


variable "app_cidr" {
  type = list(string)
}

variable "snet_app_compute_prefix" {
  type = list(string)
}

variable "snet_app_db_prefix" {
  type = list(string)
}

