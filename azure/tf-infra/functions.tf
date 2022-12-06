resource "azurerm_windows_function_app" "main" {
  for_each                   = { for app in local.deployable_apps : app.name => app if app.type == "function" }
  name                       = "${terraform.workspace}-${var.prefix}-${each.value.name}"
  location                   = azurerm_resource_group.abc.location
  resource_group_name        = azurerm_resource_group.abc.name
  service_plan_id            = azurerm_service_plan.main[each.value.service_plan_name].id
  virtual_network_subnet_id  = azurerm_subnet.apps[each.value.service_plan_name].id
  storage_account_name       = azurerm_storage_account.abc.name
  storage_account_access_key = azurerm_storage_account.abc.primary_access_key

  https_only                  = true
  functions_extension_version = "~4"

  site_config {

    vnet_route_all_enabled = true
    always_on              = true

    application_stack {
      node_version   = each.value.stack == "node" ? "~${var.node_version}" : null
      dotnet_version = each.value.stack == "dotnet" ? var.dotnet_version : null
    }
    dynamic "ip_restriction" {
      for_each = terraform.workspace == "prod" && !each.value.isPublic ? [for s in azurerm_subnet.apps : s.id] : []
      content {
        action                    = "Allow"
        virtual_network_subnet_id = ip_restriction.value
      }
    }
  }

  app_settings = merge({
    "FUNCTIONS_WORKER_RUNTIME"                                         = each.value.stack == "node" ? each.value.stack : "${each.value.stack}-isolated"
    each.value.stack == "node" ? "NODE_ENV" : "ASPNETCORE_ENVIRONMENT" = var.app_environment
    "DD_ENV"                                                           = var.app_environment
    "DD_LOGS_INJECTION"                                                = "true"
    "DD_API_KEY"                                                       = datadog_api_key.log-ingestion.key
  }, each.value.app_settings)

  dynamic "connection_string" {
    for_each = each.value.app_config_name != null ? [each.value.app_config_name] : []
    content {
      name  = "AppConfig"
      type  = "Custom"
      value = azurerm_app_configuration.main[connection_string.value].primary_read_key[0].connection_string
    }
  }

  connection_string {
    name  = "ServiceBus"
    type  = "Custom"
    value = azurerm_servicebus_namespace.abc.default_primary_connection_string
  }

  dynamic "connection_string" {
    for_each = each.value.name == "abc-func" ? [azurerm_key_vault.main.vault_uri] : []
    content {
      name  = "KeyVault"
      type  = "Custom"
      value = azurerm_key_vault.main.vault_uri
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name = each.value.name
    Repo = each.value.repo
    Env  = terraform.workspace
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      # TODO: find better way, but not just ignoring all app_settings 
      app_settings["AzureWebJobs.NetworkWithdrawal.Disabled"],
      app_settings["AzureWebJobs.WebhookNotificationFunction.Disabled"],
      app_settings["AzureWebJobs.ProfitCalculationFuntion.Disabled"],
    ]
  }
}

resource "azurerm_private_endpoint" "functions" {
  for_each = terraform.workspace == "prod" ? { for app in local.deployable_apps : app.name => app if app.type == "function" && !app.isPublic } : {}

  name                = "${each.value.name}-endpoint"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  subnet_id           = azurerm_subnet.sites-private.id

  private_service_connection {
    name                           = "${each.value.name}-endpoint-connection"
    private_connection_resource_id = azurerm_windows_function_app.main[each.value.name].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${each.value.name}-endpoint-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.sites[0].id]
  }
}