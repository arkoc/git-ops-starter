resource "azurerm_role_assignment" "main" {
  for_each             = { for x in distinct(local.deployable_apps[*].app_config_name) : x => x if x != null }
  scope                = azurerm_app_configuration.main[each.key].id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_app_configuration_key" "user-defined" {
  for_each               = { for app_config in local.app_configs : app_config.key => app_config }
  configuration_store_id = azurerm_app_configuration.main[each.value.app_config_name].id
  key                    = each.value.key
  value                  = each.value.value

  depends_on = [
    azurerm_role_assignment.main,
  ]
}


resource "azurerm_app_configuration_key" "mongo" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "ConnectionStrings:Mongo"
  value                  = local.mongo_db_connection_string

  depends_on = [
    azurerm_role_assignment.main,
    mongodbatlas_advanced_cluster.main
  ]
}


resource "azurerm_app_configuration_key" "redis" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "ConnectionStrings:Redis"
  value                  = local.redis_connection_string

  depends_on = [
    azurerm_role_assignment.main,
    azurerm_redis_cache.main
  ]
}

resource "azurerm_app_configuration_key" "servicebus" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "ConnectionStrings:ServiceBus"
  value                  = azurerm_servicebus_namespace.main.default_primary_connection_string

  depends_on = [
    azurerm_role_assignment.main,
    azurerm_servicebus_namespace.main
  ]
}


resource "azurerm_app_configuration_key" "key-vault" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "KeyVault:Url"
  value                  = azurerm_key_vault.main.vault_uri
  depends_on = [
    azurerm_role_assignment.main,
    azurerm_key_vault.main
  ]
}

data "azurerm_function_app_host_keys" "js-func-host-keys" {
  name                = azurerm_windows_function_app.main["abc-func"].name
  resource_group_name = azurerm_resource_group.abc.name
}

resource "azurerm_app_configuration_key" "access-key" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "JsFunctions:ApiKey"
  value                  = data.azurerm_function_app_host_keys.js-func-host-keys.primary_key

  depends_on = [
    azurerm_role_assignment.main,
    azurerm_windows_function_app.main["abc-func"],
  ]
}

resource "azurerm_app_configuration_key" "js-api" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "JsFunctions:BaseUrl"
  value                  = "https://${azurerm_windows_function_app.main["abc-func"].default_hostname}"

  depends_on = [
    azurerm_role_assignment.main,
    azurerm_windows_function_app.main["abc-func"],
  ]
}