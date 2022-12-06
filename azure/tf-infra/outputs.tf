output "deployable_apps" {
  value = [
    for app in local.deployable_apps :
    {
      name                  = app.name
      repo                  = app.repo
      type                  = app.type
      stack                 = app.stack
      src_project_directory = app.src_project_directory
      url                   = app.type == "function" ? "https://${azurerm_windows_function_app.main[app.name].default_hostname}" : app.isPublic ? "https://${azurerm_app_service_custom_hostname_binding.apps[app.name].hostname}" : "https://${azurerm_windows_web_app.main[app.name].default_hostname}"
    }
  ]
}

output "deployable_packages" {
  value = local.nugets
}

output "deployable_containers" {
  value = local.containers
}

output "api-outgoing-ip" {
  value = azurerm_public_ip.api.ip_address
}

output "deployed_vnet" {
  value = {
    name = azurerm_virtual_network.abc.name
    id   = azurerm_virtual_network.abc.id
  }
}

output "deployed_resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "deployed_private_dns_resolver_ip" {
  value = terraform.workspace == "prod" ? azurerm_private_dns_resolver_inbound_endpoint.main[0].ip_configurations[0].private_ip_address : null
}

output "deployed_private_dns_zone_names" {
  value = terraform.workspace == "prod" ? [
    azurerm_private_dns_zone.database-server[0].name,
    azurerm_private_dns_zone.servicebus[0].name,
    azurerm_private_dns_zone.key-vault[0].name,
    azurerm_private_dns_zone.redis[0].name,
  azurerm_private_dns_zone.sites[0].name] : []
}

output "deployed_vercel_url" {
  value = vercel_project_domain.main.domain
}

output "dotnet_version" {
  value = var.dotnet_version
}

output "node_version" {
  value = var.node_version
}

output "deployed_app_config_connection_string" {
  value     = azurerm_app_configuration.main.primary_read_key[0].connection_string
  sensitive = true
}