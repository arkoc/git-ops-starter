resource "azurerm_container_registry" "abc" {
  name                = "abccontainerhub"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "acr-k8s" {
  principal_id                     = azuread_service_principal.k8s.object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.abc.id
  skip_service_principal_aad_check = true
}