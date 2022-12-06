locals {
  redis_connection_string = azurerm_redis_cache.main.primary_connection_string
}

resource "azurerm_redis_cache" "main" {
  name                          = "${terraform.workspace}-${var.prefix}-redis"
  location                      = azurerm_resource_group.abc.location
  resource_group_name           = azurerm_resource_group.abc.name
  capacity                      = var.default_redis_capacity
  family                        = var.default_redis_family
  sku_name                      = var.default_redis_sku
  enable_non_ssl_port           = false
  minimum_tls_version           = "1.2"
  redis_version                 = 6
  public_network_access_enabled = terraform.workspace != "prod"

  dynamic "redis_configuration" {
    for_each = terraform.workspace == "prod" ? [1] : []
    content {
      aof_backup_enabled              = true
      aof_storage_connection_string_0 = azurerm_storage_account.abc.primary_blob_connection_string
    }
  }

  lifecycle {
    # https://github.com/Azure/azure-rest-api-specs/issues/3037
    ignore_changes = [redis_configuration.0.aof_storage_connection_string_0]
  }
}

resource "azurerm_private_dns_zone" "redis" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.abc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  count                 = terraform.workspace == "prod" ? 1 : 0
  name                  = "${terraform.workspace}-${var.prefix}-private-dns-redis-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis[count.index].name
  virtual_network_id    = azurerm_virtual_network.abc.id
  resource_group_name   = azurerm_resource_group.abc.name
}

resource "azurerm_private_endpoint" "redis" {
  count = terraform.workspace == "prod" ? 1 : 0

  name                = "${terraform.workspace}-${var.prefix}-redis-endpoint"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  subnet_id           = azurerm_subnet.redis.id

  private_service_connection {
    name                           = "${terraform.workspace}-${var.prefix}-endpoint-redis"
    private_connection_resource_id = azurerm_redis_cache.main.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis-endpoint-dnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis[0].id]
  }
}