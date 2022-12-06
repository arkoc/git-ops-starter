locals {
  deployable_apps_configs_names = distinct(local.deployable_apps[*].app_config_name)
}

resource "azurerm_app_configuration" "main" {
  name                  = "${terraform.workspace}-${var.prefix}-main"
  resource_group_name   = azurerm_resource_group.abc.name
  location              = azurerm_resource_group.abc.location
  sku                   = "standard"
  public_network_access = "Enabled"
}