variable "resource_group_name" {
  type    = string
  default = "tp-devsecops-rg"
}

variable "azure_region" {
  type    = string
  default = "West Europe"
}

variable "app_name" {
  type    = string
  default = "tp-devsecops-prod"
}

variable "docker_image" {
  type = string
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

variable "registry_url" {
  type = string
}

variable "registry_user" {
  type      = string
  sensitive = true
}

variable "registry_password" {
  type      = string
  sensitive = true
}
