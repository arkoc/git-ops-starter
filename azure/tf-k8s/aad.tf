resource "azuread_application" "k8s" {
  display_name = "k8s"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "k8s" {
  application_id = azuread_application.k8s.application_id
  owners         = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "k8s" {
  service_principal_id = azuread_service_principal.k8s.object_id
}

resource "azurerm_role_assignment" "k8s" {
  scope                = data.azurerm_subscription.abc.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.k8s.object_id
}