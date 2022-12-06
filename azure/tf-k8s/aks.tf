locals {
  cluster_name = "${var.prefix}-aks"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                    = local.cluster_name
  location                = azurerm_resource_group.k8s.location
  resource_group_name     = azurerm_resource_group.k8s.name
  dns_prefix              = local.cluster_name
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = var.enable_private_cluster

  default_node_pool {
    name                 = "default"
    node_count           = 1
    vm_size              = "Standard_D2_v2"
    orchestrator_version = var.kubernetes_version
    vnet_subnet_id       = azurerm_subnet.k8s.id
  }

  service_principal {
    client_id     = azuread_service_principal.k8s.application_id
    client_secret = azuread_service_principal_password.k8s.value
  }

  network_profile {
    network_plugin     = "azure"
    docker_bridge_cidr = "172.18.0.1/16"
    dns_service_ip     = "10.0.0.10"
    service_cidr       = "10.0.0.0/16"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each              = toset(var.target_workspaces)
  name                  = each.value
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  vm_size               = var.default_node_size
  node_count            = var.default_node_count
  vnet_subnet_id        = azurerm_subnet.k8s.id
  enable_auto_scaling   = var.enable_auto_scaling
  orchestrator_version  = var.kubernetes_version
}