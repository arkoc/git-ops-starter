resource "helm_release" "azure-ingress-controller" {
  name       = "ingress-controller"
  repository = "https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/"
  chart      = "ingress-azure"

  set {
    name  = "appgw.applicationGatewayID"
    value = azurerm_application_gateway.k8s.id
  }

  set {
    name  = "appgw.name"
    value = azurerm_application_gateway.k8s.name
  }
  set {
    name  = "appgw.resourceGroup"
    value = azurerm_application_gateway.k8s.resource_group_name
  }
  set {
    name  = "appgw.subscriptionId"
    value = data.azurerm_client_config.current.subscription_id
  }
  set {
    name  = "armAuth.type"
    value = "servicePrincipal"
  }
  set {
    name  = "rbac.enabled"
    value = true
  }
  set {
    name = "armAuth.secretJSON"
    value = base64encode(jsonencode({
      "clientId"                       = azuread_service_principal.k8s.application_id,
      "clientSecret"                   = azuread_service_principal_password.k8s.value,
      "subscriptionId"                 = data.azurerm_client_config.current.subscription_id,
      "tenantId"                       = data.azurerm_client_config.current.tenant_id,
      "activeDirectoryEndpointUrl"     = "https://login.microsoftonline.com",
      "activeDirectoryGraphResourceId" = "https://graph.windows.net/",
      "resourceManagerEndpointUrl"     = "https://management.azure.com/",
      "sqlManagementEndpointUrl"       = "https://management.core.windows.net:8443/",
      "galleryEndpointUrl"             = "https://gallery.azure.com/",
      "managementEndpointUrl"          = "https://management.core.windows.net/"
    }))
  }

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    azurerm_role_assignment.k8s
  ]
}