resource "azurerm_servicebus_namespace" "abc" {
  name                          = "${terraform.workspace}-${var.prefix}-abcsb"
  location                      = azurerm_resource_group.abc.location
  resource_group_name           = azurerm_resource_group.abc.name
  sku                           = var.default_service_bus_sku
  capacity                      = var.default_service_bus_capacity
  public_network_access_enabled = terraform.workspace != "prod"
}

resource "azurerm_servicebus_queue" "example-queue" {
  name                                 = "example-q1"
  namespace_id                         = azurerm_servicebus_namespace.abc.id
  max_delivery_count                   = 1
  dead_lettering_on_message_expiration = true
}


resource "azurerm_servicebus_topic" "example-topic" {
  name         = "example-t1"
  namespace_id = azurerm_servicebus_namespace.abc.id
}

resource "azurerm_servicebus_subscription" "example-subscription-default" {
  name               = "default"
  topic_id           = azurerm_servicebus_topic.example-topic.id
  max_delivery_count = 1
}

resource "azurerm_private_endpoint" "servicebus" {
  count = terraform.workspace == "prod" ? 1 : 0

  name                = "${terraform.workspace}-${var.prefix}-abcsb-endpoint"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  subnet_id           = azurerm_subnet.sb.id

  private_service_connection {
    name                           = "${terraform.workspace}-${var.prefix}-endpoint-namespace"
    private_connection_resource_id = azurerm_servicebus_namespace.abc.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "servicebus-endpoint-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.servicebus[0].id]
  }

}

resource "azurerm_private_dns_zone" "servicebus" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.abc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "namespace" {
  count                 = terraform.workspace == "prod" ? 1 : 0
  name                  = "${terraform.workspace}-${var.prefix}-private-dns-namespace-link"
  private_dns_zone_name = azurerm_private_dns_zone.servicebus[count.index].name
  virtual_network_id    = azurerm_virtual_network.abc.id
  resource_group_name   = azurerm_resource_group.abc.name
}