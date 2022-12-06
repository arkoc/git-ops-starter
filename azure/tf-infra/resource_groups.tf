resource "azurerm_resource_group" "abc" {
  name     = "${terraform.workspace}-${var.prefix}-${var.resource_group}"
  location = var.location
}