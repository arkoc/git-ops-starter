variable "prefix" {
  type    = string
  default = "abc"
}

variable "resource_group" {
  type = string
}

variable "location" {
  type = string
}

variable "postgres_admin_user" {
  type      = string
  sensitive = true
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "mongo_admin_user" {
  type      = string
  sensitive = true
}

variable "mongo_admin_password" {
  type      = string
  sensitive = true
}

variable "mongo_atlas_project_id" {
  type = string
}

variable "app_environment" {
  type = string
}

variable "default_app_service_plan" {
  type    = string
  default = "B1"
}

variable "default_redis_sku" {
  type    = string
  default = "Standard"
}

variable "default_redis_family" {
  type    = string
  default = "C"
}

variable "default_redis_capacity" {
  type    = number
  default = 0
}

variable "default_postgres_sku" {
  type    = string
  default = "GP_Standard_D2s_v3"
}

variable "default_storage_in_mb" {
  type    = string
  default = 32768
}

variable "default_mongo_instance_size" {
  type    = string
  default = "M10"
}

variable "default_service_bus_sku" {
  type    = string
  default = "Standard"
}

variable "default_service_bus_capacity" {
  type    = number
  default = 0
}

variable "postgres_db_name" {
  type    = string
  default = "abc_db"
}


variable "vercel_project_id" {
  type    = string
  default = "value"
}

variable "vercel_team_id" {
  type    = string
  default = "value"
}

variable "vnet_address_space_prefix" {
  type = string
}

variable "vnet_vpn_gateway_prefix" {
  type = string
}

variable "key_vault_admins" {
  type = list(string)
}

variable "vpn_users" {
  type    = list(string)
  default = []
}

variable "app_service_plan_tiers" {
  type    = map(string)
  default = {}
}

variable "dotnet_version" {
  type = string
}

variable "node_version" {
  type = string
}