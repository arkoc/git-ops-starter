locals {
  resource_group_name = "${terraform.workspace}-${var.prefix}"
}

resource "azurerm_resource_group" "devops" {
  name     = "${terraform.workspace}-${var.prefix}"
  location = var.location
}

resource "azurerm_virtual_network" "devops" {
  name                = "${terraform.workspace}-${var.prefix}-vnet"
  address_space       = ["11.0.0.0/16"]
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name
}

resource "azurerm_subnet" "vmss" {
  name                 = "vmss"
  resource_group_name  = azurerm_resource_group.devops.name
  virtual_network_name = azurerm_virtual_network.devops.name
  address_prefixes     = ["11.0.2.0/24"]
}

data "terraform_remote_state" "prod" {
  backend = "remote"

  config = {
    organization = "abc"
    workspaces = {
      name = "prod"
    }
  }
}

resource "azurerm_virtual_network_peering" "devops-to-vnet" {
  name                         = "devops-to-main"
  resource_group_name          = azurerm_virtual_network.devops.resource_group_name
  virtual_network_name         = azurerm_virtual_network.devops.name
  remote_virtual_network_id    = data.terraform_remote_state.prod.outputs.deployed_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = true
}

resource "azurerm_virtual_network_peering" "vnet-to-devops" {
  name                         = "main-to-devops"
  resource_group_name          = data.terraform_remote_state.prod.outputs.deployed_resource_group_name
  virtual_network_name         = data.terraform_remote_state.prod.outputs.deployed_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.devops.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = { for d in data.terraform_remote_state.prod.outputs.deployed_private_dns_zone_names : d => d }
  name                  = "${terraform.workspace}-${var.prefix}-private-link"
  resource_group_name   = data.terraform_remote_state.prod.outputs.deployed_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.devops.id
}

resource "azurerm_image" "ubuntu22" {
  name                = "ubuntu22-build-agent"
  location            = azurerm_resource_group.devops.location
  resource_group_name = azurerm_resource_group.devops.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.ubuntu_22_agent_vhd_blob_url
  }
}


resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                        = "${var.prefix}-build-agents-vmss"
  resource_group_name         = local.resource_group_name
  location                    = var.location
  sku                         = "Standard_D2_v3"
  admin_username              = "lsadmin"
  overprovision               = false
  upgrade_mode                = "Manual"
  single_placement_group      = false
  platform_fault_domain_count = 1

  admin_password                  = var.agent_vmss_password
  disable_password_authentication = false

  source_image_id = azurerm_image.ubuntu22.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "agent-vmss-network"
    primary = true

    ip_configuration {
      name      = "agent-vmss-ip"
      primary   = true
      subnet_id = azurerm_subnet.vmss.id
    }
  }

  lifecycle {
    ignore_changes = [
      instances,
      tags
    ]
  }
}