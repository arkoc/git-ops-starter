resource "azurerm_resource_group" "k8s" {
  name     = "${terraform.workspace}-${var.prefix}"
  location = var.location
}