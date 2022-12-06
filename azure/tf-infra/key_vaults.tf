locals {
  kv_admin_secret_permission = [
    "Get",
    "Set",
    "List",
    "Purge",
    "Delete",
    "Recover",
    "Restore"
  ]
}

resource "azurerm_key_vault" "main" {
  name                          = "${terraform.workspace}-${var.prefix}-main"
  location                      = azurerm_resource_group.abc.location
  resource_group_name           = azurerm_resource_group.abc.name
  enabled_for_disk_encryption   = true
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = terraform.workspace != "prod"
  sku_name                      = "standard"
}

resource "azurerm_key_vault_access_policy" "main-kv-admins" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azuread_group.key-vault-admins.object_id

  secret_permissions = local.kv_admin_secret_permission
}


resource "azurerm_key_vault_access_policy" "api" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_windows_web_app.main["api"].identity[0].principal_id

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_private_dns_zone" "key-vault" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key-vault" {
  count                 = terraform.workspace == "prod" ? 1 : 0
  name                  = "${terraform.workspace}-${var.prefix}-private-dns-keyvault-link"
  private_dns_zone_name = azurerm_private_dns_zone.key-vault[count.index].name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = azurerm_resource_group.main.name
}

resource "azurerm_private_endpoint" "kv" {
  count = terraform.workspace == "prod" ? 1 : 0

  name                = "${terraform.workspace}-${var.prefix}-kv-endpoint"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  subnet_id           = azurerm_subnet.kv.id

  private_service_connection {
    name                           = "${terraform.workspace}-${var.prefix}-endpoint-main-kv"
    private_connection_resource_id = azurerm_key_vault.abc.id
    subresource_names              = ["Vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "main-kv-endpoint-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.key-vault[0].id]
  }
}