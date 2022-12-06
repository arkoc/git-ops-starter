resource "vercel_project_domain" "abc" {
  project_id = var.vercel_project_id
  team_id    = var.vercel_team_id
  domain     = "app${local.cname_sufix}.${local.root_domain}"
  git_branch = terraform.workspace == "prod" ? null : terraform.workspace

  depends_on = [
    time_sleep.vercel-dns-timeout
  ]
}

resource "vercel_project_environment_variable" "api" {
  project_id = var.vercel_project_id
  team_id    = var.vercel_team_id
  key        = "NEXT_PUBLIC_API"
  value      = "https://${azurerm_app_service_custom_hostname_binding.apps["api"].hostname}/"
  target     = terraform.workspace == "prod" ? ["production"] : ["preview"]
}
