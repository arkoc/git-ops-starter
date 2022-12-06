locals {
  db_host_name                            = azurerm_postgresql_flexible_server.main.fqdn
  postgres_db_connection_string  = "Server=${local.db_host_name};Database=${var.postgres_db_name};Port=5432;User Id=${azurerm_postgresql_flexible_server.main.administrator_login};Password=${azurerm_postgresql_flexible_server.main.administrator_password};Ssl Mode=Require;Trust Server Certificate=true;"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${terraform.workspace}-${var.prefix}-psqlserver"
  resource_group_name    = azurerm_resource_group.abc.name
  location               = azurerm_resource_group.abc.location
  version                = "12"
  delegated_subnet_id    = terraform.workspace == "prod" ? azurerm_subnet.postgres.id : null
  private_dns_zone_id    = terraform.workspace == "prod" ? azurerm_private_dns_zone.main-database-server[0].id : null
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_admin_password
  zone                   = "1"

  storage_mb = var.default_storage_in_mb

  sku_name   = var.default_postgres_sku
  depends_on = [azurerm_private_dns_zone_virtual_network_link.main-database]

}

resource "azurerm_postgresql_flexible_server_configuration" "main" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "UUID-OSSP"
}

resource "azurerm_private_dns_zone" "database-server" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "${terraform.workspace}-${var.prefix}-abc-psql.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.abc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main-database" {
  count                 = terraform.workspace == "prod" ? 1 : 0
  name                  = "${terraform.workspace}-${var.prefix}-private-dns-database-link"
  private_dns_zone_name = azurerm_private_dns_zone.main-database-server[count.index].name
  virtual_network_id    = azurerm_virtual_network.abc.id
  resource_group_name   = azurerm_resource_group.abc.name
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "example" {
  count            = terraform.workspace != "prod" ? 1 : 0
  name             = "allow-all"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}