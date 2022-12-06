resource "azurerm_storage_account" "abc" {
  name                     = "${terraform.workspace}${var.prefix}generalsa"
  resource_group_name      = azurerm_resource_group.abc.name
  location                 = azurerm_resource_group.abc.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_network_rules" "abc-sa" {
  count              = terraform.workspace == "prod" ? 1 : 0
  storage_account_id = azurerm_storage_account.abc.id

  default_action             = "Deny"
  virtual_network_subnet_ids = [for s in azurerm_subnet.apps : s.id]
  bypass                     = ["AzureServices", "Logging", "Metrics"]
}