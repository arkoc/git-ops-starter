resource "azurerm_virtual_network" "k8s" {
  name                = "${terraform.workspace}-${var.prefix}-vnet"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  address_space       = ["172.17.0.0/16"]
}

resource "azurerm_subnet" "k8s" {
  name                 = "aks"
  virtual_network_name = azurerm_virtual_network.k8s.name
  resource_group_name  = azurerm_resource_group.k8s.name
  address_prefixes     = ["172.17.0.0/24"]
}

resource "azurerm_subnet" "app_gateway" {
  name                 = "app_gateway"
  virtual_network_name = azurerm_virtual_network.k8s.name
  resource_group_name  = azurerm_resource_group.k8s.name
  address_prefixes     = ["172.17.1.0/24"]
}

resource "azurerm_virtual_network_peering" "k8s-to-vnet" {
  name                         = "k8s-to-main"
  resource_group_name          = azurerm_virtual_network.k8s.resource_group_name
  virtual_network_name         = azurerm_virtual_network.k8s.name
  remote_virtual_network_id    = data.terraform_remote_state.prod.outputs.deployed_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "vnet-to-k8s" {
  name                         = "main-to-k8s"
  resource_group_name          = data.terraform_remote_state.prod.outputs.deployed_resource_group_name
  virtual_network_name         = data.terraform_remote_state.prod.outputs.deployed_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.k8s.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = { for d in data.terraform_remote_state.prod.outputs.deployed_private_dns_zone_names : d => d }
  name                  = "${terraform.workspace}-${var.prefix}-private-link"
  resource_group_name   = data.terraform_remote_state.prod.outputs.deployed_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.k8s.id
}