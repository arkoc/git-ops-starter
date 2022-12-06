variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "enable_auto_scaling" {
  type    = bool
  default = false
}

variable "default_node_count" {
  description = "Specifies the count of the nodes in the node pool"
  type        = number
  default     = 1
}

variable "default_node_size" {
  description = "Specifies the size for the node in the node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "kubernetes_version" {
  description = "Specifies the AKS Kubernetes version"
  default     = "1.23"
  type        = string
}

variable "target_workspaces" {
  type = set(string)
}

variable "default_workspace" {
  type    = string
  default = "dev"
}

variable "enable_private_cluster" {
  type    = bool
  default = false
}

variable "cloudflare_cert_manager_token" {
  type      = string
  sensitive = true
}

variable "github_owner" {
  type        = string
  description = "github owner"
  default     = "abc"
}

variable "flux_repository_name" {
  type        = string
  default     = "abc-flux"
  description = "github repository name"
}

variable "flux_notification_webhook" {
  type      = string
  sensitive = true
}