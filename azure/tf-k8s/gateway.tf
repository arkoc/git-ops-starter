locals {
  frontend_ip_configuration_name = "gateway-frontend-ip-config"
  app_gateway_private_ip         = "172.17.1.10"
}

resource "azurerm_public_ip" "app_gateway" {
  name                = "app_gateway_ip"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "k8s" {
  name                = "k8s-app-gateway"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "AppGateway-Ip-Config"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}-public"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  frontend_ip_configuration {
    name                          = "${local.frontend_ip_configuration_name}-private"
    subnet_id                     = azurerm_subnet.app_gateway.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.app_gateway_private_ip
  }

  # => This is automatically removed by Kubernetes, because in fact applicaiton gateway is managed by it
  frontend_port {
    name = "ls-default-port"
    port = 63333
  }

  backend_address_pool {
    name = "ls-default-backend-address-pool"
  }

  http_listener {
    name                           = "ls-default-listener"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}-public"
    frontend_port_name             = "ls-default-port"
    protocol                       = "Http"
  }

  backend_http_settings {
    name                  = "ls-default-backend-http-settings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  request_routing_rule {
    name                       = "ls-default-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "ls-default-listener"
    backend_address_pool_name  = "ls-default-backend-address-pool"
    backend_http_settings_name = "ls-default-backend-http-settings"
    priority                   = 1
  }

  lifecycle {
    ignore_changes = [
      ssl_certificate,
      url_path_map,
      tags,
      probe,
      frontend_port,
      request_routing_rule,
      backend_address_pool,
      http_listener,
      backend_http_settings
    ]
  }
  # <=
}