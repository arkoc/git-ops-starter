locals {
  deployable_apps = [
    {
      name                  = "api"
      repo                  = "abc/abc-api"
      src_project_directory = "src/API"
      service_plan_name     = "api"
      app_config_name       = "main"
      type                  = "appservice"
      stack                 = "dotnet"
      isPublic              = true
      app_settings          = {}
    },
    {
      name                  = "abc-func"
      repo                  = "abc/abc-function"
      src_project_directory = "src/Functions"
      service_plan_name     = "functions"
      app_config_name       = "main"
      type                  = "function"
      stack                 = "node"
      isPublic              = false
      app_settings          = {}
    },
  ]

  nugets = [
    {
      name                  = "sdk"
      repo                  = "abc/abc-sdk"
      src_project_directory = "src/Sdk"
    }
  ]

  app_configs = [
    {
      key             = "CustomConfig:ConfigName"
      value           = "pre-configured-value"
      app_config_name = "main"
    },
  ]

  containers = [
    {
      name                  = "sample"
      repo                  = "abc/sample"
      src_project_directory = "src/Jobs"
      image_name            = "sample"
    }
  ]
}
