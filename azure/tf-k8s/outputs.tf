output "deployed_acr" {
  value = {
    resource_group = azurerm_container_registry.abc.resource_group_name
    name           = azurerm_container_registry.abc.name
    id             = azurerm_container_registry.abc.id
  }
}

output "flux_repo_full_name" {
  value = github_repository.flux.full_name
}