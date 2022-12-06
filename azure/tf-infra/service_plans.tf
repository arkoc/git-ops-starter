locals {
  app_serivce_plans = distinct(local.deployable_apps[*].service_plan_name)
}

resource "azurerm_service_plan" "main" {
  for_each            = { for x in local.app_serivce_plans : x => x }
  name                = "${terraform.workspace}-${var.prefix}-${each.value}"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  os_type             = "Windows"
  sku_name            = lookup(var.app_service_plan_tiers, each.value, var.default_app_service_plan)
}