resource "datadog_api_key" "log-ingestion" {
  name = "${terraform.workspace}-ingestion-key"
}

resource "azurerm_resource_group_template_deployment" "datadog-extension" {
  for_each            = merge({ for func in azurerm_windows_function_app.main : func.name => func.name }, { for app in azurerm_windows_web_app.main : app.name => app.name })
  name                = "${each.value}-datadog"
  resource_group_name = azurerm_resource_group.abc.name
  deployment_mode     = "Incremental"
  template_content    = file("arm/siteextensions.json")

  parameters_content = jsonencode({
    "siteName" = {
      value = each.value
    }
    "extensionName" = {
      value = "Datadog.AzureAppServices.DotNet"
    }
    "extensionVersion" = {
      value = "2.18.0"
    }
  })

}