variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "agents_counts" {
  type = number
}

variable "devops_org_name" {
  type    = string
  default = "abchq"
}

variable "devops_pat_token_for_agents" {
  type      = string
  sensitive = true
}

variable "docker_username" {
  type = string
}

variable "docker_email" {
  type = string
}

variable "docker_password" {
  type      = string
  sensitive = true
}

variable "agent_vmss_password" {
  type      = string
  sensitive = true
}

variable "ubuntu_22_agent_vhd_blob_url" {
  type    = string
  default = "" # link to build agent vhd blob
}