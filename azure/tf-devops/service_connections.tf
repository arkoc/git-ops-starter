locals {
  registry_type = "DockerHub"
}

resource "azuredevops_serviceendpoint_github" "pat" {
  project_id            = data.azuredevops_project.abc.project_id
  service_endpoint_name = "Terraform PAT Token"
  description           = "Managed by Terraform"

  auth_personal {}
}

resource "azuredevops_serviceendpoint_dockerregistry" "abc" {
  project_id            = data.azuredevops_project.abc.id
  service_endpoint_name = local.registry_type
  docker_username       = var.docker_username
  docker_email          = var.docker_email
  docker_password       = var.docker_password
  registry_type         = local.registry_type
}

resource "azuredevops_serviceendpoint_azurecr" "abc" {
  project_id                = data.azuredevops_project.abc.id
  service_endpoint_name     = "ABC AzureCR"
  resource_group            = data.terraform_remote_state.k8s.outputs.deployed_acr.resource_group
  azurecr_spn_tenantid      = data.azurerm_subscription.current.tenant_id
  azurecr_name              = data.terraform_remote_state.k8s.outputs.deployed_acr.name
  azurecr_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurecr_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_serviceendpoint_azurerm" "abc" {
  project_id                = data.azuredevops_project.abc.id
  service_endpoint_name     = "ABC Azure"
  azurerm_spn_tenantid      = data.azurerm_subscription.current.tenant_id
  azurerm_subscription_id   = data.azurerm_subscription.current.subscription_id
  azurerm_subscription_name = data.azurerm_subscription.current.display_name
}

resource "azuredevops_resource_authorization" "abc_azure" {
  project_id  = data.azuredevops_project.abc.id
  resource_id = azuredevops_serviceendpoint_azurerm.abc.id
  authorized  = true
}

resource "azuredevops_resource_authorization" "abcacr" {
  project_id  = data.azuredevops_project.abc.id
  resource_id = azuredevops_serviceendpoint_azurecr.abc.id
  authorized  = true
}