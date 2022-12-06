resource "azurerm_windows_web_app" "main" {
  for_each                  = { for app in local.deployable_apps : app.name => app if app.type == "appservice" }
  name                      = "${terraform.workspace}-${var.prefix}-${each.value.name}"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  service_plan_id           = azurerm_service_plan.main[each.value.service_plan_name].id
  virtual_network_subnet_id = azurerm_subnet.apps[each.value.service_plan_name].id
  https_only                = true

  site_config {

    always_on              = true
    vnet_route_all_enabled = true

    dynamic "ip_restriction" {
      for_each = terraform.workspace == "prod" && !each.value.isPublic ? [for s in azurerm_subnet.apps : s.id] : []
      content {
        action                    = "Allow"
        virtual_network_subnet_id = ip_restriction.value
      }
    }
  }

  app_settings = merge({
    "ASPNETCORE_ENVIRONMENT" = var.app_environment
    "DD_ENV"                 = var.app_environment
    "DD_LOGS_INJECTION"      = "true"
    "DD_API_KEY"             = datadog_api_key.log-ingestion.key
  }, each.value.app_settings)

  connection_string {
    name  = "AppConfig"
    type  = "Custom"
    value = azurerm_app_configuration.main[each.value.app_config_name].primary_read_key[0].connection_string
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
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}

resource "azurerm_private_endpoint" "appservices" {
  for_each = terraform.workspace == "prod" ? { for app in local.deployable_apps : app.name => app if app.type == "appservice" && !app.isPublic } : {}

  name                = "${each.value.name}-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.sites-private.id

  private_service_connection {
    name                           = "${each.value.name}-endpoint-connection"
    private_connection_resource_id = azurerm_windows_web_app.main[each.value.name].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${each.value.name}-endpoint-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.sites[0].id]
  }
}