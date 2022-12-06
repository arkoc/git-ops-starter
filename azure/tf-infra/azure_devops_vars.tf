data "azuredevops_project" "abc" {
  name = "ABC"
}

resource "azuredevops_variable_group" "env" {
  project_id   = data.azuredevops_project.abc.id
  name         = terraform.workspace
  description  = "${terraform.workspace} variables"
  allow_access = true

  variable {
    name         = "Db_ConnectionString"
    secret_value = local.postgres_db_connection_string
    is_secret    = true
  }

  variable {
    name  = "Dotnet_Version"
    value = var.dotnet_version
  }

  dynamic "variable" {
    for_each = { for app in local.deployable_apps : app.name => app }
    content {
      name  = variable.value.name
      value = variable.value.type == "function" ? azurerm_windows_function_app.main[variable.value.name].name : azurerm_windows_web_app.main[variable.value.name].name
    }
  }
}
