locals {
  signin_url = "https://%s/signin-oidc"
}

data "azuread_users" "key_vault_admins" {
  user_principal_names = var.key_vault_admins
}

resource "azuread_group" "key-vault-admins" {
  display_name     = "Key Vault Admins ${upper(terraform.workspace)}"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = data.azuread_users.key_vault_admins.object_ids
}

data "azuread_service_principal" "azure-vpn" {
  application_id = local.azure_vpn_app_id
}

data "azuread_users" "vpn-users" {
  user_principal_names = var.vpn_users
}

resource "azuread_group" "vpn-admins" {
  count            = terraform.workspace == "prod" ? 1 : 0
  display_name     = "VPN Users ${upper(terraform.workspace)}"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = data.azuread_users.vpn-users.object_ids
}

resource "azuread_app_role_assignment" "azure-vpn" {
  count               = terraform.workspace == "prod" ? 1 : 0
  app_role_id         = "00000000-0000-0000-0000-000000000000" # Default Access role
  principal_object_id = azuread_group.vpn-admins[0].object_id
  resource_object_id  = data.azuread_service_principal.azure-vpn.object_id
}