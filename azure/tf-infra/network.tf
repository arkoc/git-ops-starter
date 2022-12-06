locals {
  default_service_endpoints = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.ServiceBus", "Microsoft.KeyVault"]
  azure_vpn_app_id          = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
}

resource "azurerm_virtual_network" "abc" {
  name                = "${terraform.workspace}-${var.prefix}-vnet"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  address_space       = ["${var.vnet_address_space_prefix}.0.0/16"]
}

locals {
  # subnet can be associated with only one service plan
  deployable_apps_subnets = distinct(local.deployable_apps[*].service_plan_name)
}

resource "azurerm_subnet" "apps" {
  for_each                                  = { for x in local.deployable_apps_subnets : x => x }
  name                                      = each.value
  resource_group_name                       = azurerm_resource_group.abc.name
  virtual_network_name                      = azurerm_virtual_network.abc.name
  address_prefixes                          = ["${var.vnet_address_space_prefix}.${20 + index(local.deployable_apps_subnets, each.value)}.0/24"]
  service_endpoints                         = local.default_service_endpoints
  private_endpoint_network_policies_enabled = true

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = "postgres"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.101.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "redis" {
  name                                      = "redis"
  resource_group_name                       = azurerm_resource_group.abc.name
  virtual_network_name                      = azurerm_virtual_network.abc.name
  address_prefixes                          = ["${var.vnet_address_space_prefix}.102.0/24"]
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "mongodb" {
  name                 = "mongodb"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.103.0/24"]
}

resource "azurerm_subnet" "sb" {
  name                 = "sb"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.105.0/24"]

  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "sites-private" {
  name                 = "sites-private-link"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.106.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}


resource "azurerm_subnet" "kv" {
  name                 = "kv"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.107.0/24"]

  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "private-dns-inbound" {
  name                 = "private-dns-inbound"
  resource_group_name  = azurerm_resource_group.abc.name
  virtual_network_name = azurerm_virtual_network.abc.name
  address_prefixes     = ["${var.vnet_address_space_prefix}.109.0/24"]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_private_dns_resolver" "abc" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "abc-dns-resolver"
  resource_group_name = azurerm_resource_group.abc.name
  location            = azurerm_resource_group.abc.location
  virtual_network_id  = azurerm_virtual_network.abc.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "abc" {
  count                   = terraform.workspace == "prod" ? 1 : 0
  name                    = "dns-private-inboud"
  private_dns_resolver_id = azurerm_private_dns_resolver.abc[0].id
  location                = azurerm_resource_group.abc.location

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.private-dns-inbound.id
  }
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # do not rename
  address_prefixes     = ["${var.vnet_address_space_prefix}.254.0/24"]
  virtual_network_name = azurerm_virtual_network.abc.name
  resource_group_name  = azurerm_resource_group.abc.name
  service_endpoints    = local.default_service_endpoints
}

resource "azurerm_public_ip" "gateway" {
  name                = "${terraform.workspace}-${var.prefix}-gateway-ip"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  allocation_method   = "Dynamic"
}


resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${terraform.workspace}-vpn-gateway"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw2"

  ip_configuration {
    name                          = "${terraform.workspace}-vnet"
    public_ip_address_id          = azurerm_public_ip.gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  vpn_client_configuration {

    address_space        = ["${var.vnet_vpn_gateway_prefix}.0.0/24"]
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["AAD"]

    aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/"
    aad_audience = local.azure_vpn_app_id # Azure VPN static app
    aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }
}

resource "azurerm_public_ip" "api" {
  name                = "${terraform.workspace}-${var.prefix}-api-ip"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "api" {
  name                    = "${terraform.workspace}-api-nat"
  location                = azurerm_resource_group.abc.location
  resource_group_name     = azurerm_resource_group.abc.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "api" {
  nat_gateway_id       = azurerm_nat_gateway.api.id
  public_ip_address_id = azurerm_public_ip.api.id
}

resource "azurerm_subnet_nat_gateway_association" "api" {
  subnet_id      = azurerm_subnet.apps["api"].id
  nat_gateway_id = azurerm_nat_gateway.api.id
}