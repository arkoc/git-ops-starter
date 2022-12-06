resource "azurerm_private_dns_zone" "sites" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.abc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sites" {
  count                 = terraform.workspace == "prod" ? 1 : 0
  name                  = "${terraform.workspace}-${var.prefix}-private-dns-sites-link"
  private_dns_zone_name = azurerm_private_dns_zone.sites[count.index].name
  virtual_network_id    = azurerm_virtual_network.abc.id
  resource_group_name   = azurerm_resource_group.abc.name
}