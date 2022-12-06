locals {
  root_domain = terraform.workspace == "prod" ? "abc.io" : "abc.cloud"
  cname_sufix = terraform.workspace == "prod" ? "" : "-${terraform.workspace}"
  public_apps = { for app in local.deployable_apps : app.name => app if app.type == "appservice" && app.isPublic }
}

data "cloudflare_zone" "abc" {
  name = local.root_domain
}

resource "cloudflare_zone_settings_override" "ssl-settings" {
  zone_id = data.cloudflare_zone.abc.zone_id

  settings {
    tls_1_3                  = "on"
    automatic_https_rewrites = "on"
    ssl                      = "full"
  }
}

resource "tls_private_key" "origin" {
  algorithm = "RSA"
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem

  subject {
    common_name  = local.root_domain
    organization = "ABC"
  }
}

resource "cloudflare_origin_ca_certificate" "abc" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = [local.root_domain, "*.${local.root_domain}"]
  request_type       = "origin-rsa"
  requested_validity = 5475
}

resource "pkcs12_from_pem" "azure-cert" {
  password        = "terraform"
  cert_pem        = cloudflare_origin_ca_certificate.abc.certificate
  private_key_pem = tls_private_key.origin.private_key_pem
}

resource "cloudflare_record" "app-verification" {
  for_each = local.public_apps
  zone_id  = data.cloudflare_zone.abc.id
  name     = "asuid.${each.value.name}${local.cname_sufix}"
  value    = azurerm_windows_web_app.main[each.value.name].custom_domain_verification_id
  type     = "TXT"
  proxied  = false
}

resource "cloudflare_record" "app-cname" {
  for_each = local.public_apps
  zone_id  = data.cloudflare_zone.abc.id
  name     = "${each.value.name}${local.cname_sufix}"
  value    = azurerm_windows_web_app.main[each.value.name].default_hostname
  type     = "CNAME"
  proxied  = true
}

resource "time_sleep" "dns-timeout" {
  for_each        = local.public_apps
  create_duration = "60s"

  triggers = {
    cname = cloudflare_record.app-cname[each.value.name].id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "apps" {
  for_each            = local.public_apps
  hostname            = "${each.value.name}${local.cname_sufix}.${local.root_domain}"
  app_service_name    = azurerm_windows_web_app.main[each.value.name].name
  resource_group_name = azurerm_resource_group.abc.name
  depends_on = [
    cloudflare_record.app-cname,
    cloudflare_record.app-verification,
    time_sleep.dns-timeout
  ]
}

resource "azurerm_app_service_certificate" "cloudflare" {
  name                = "${terraform.workspace}-abc-cf-cert"
  resource_group_name = azurerm_resource_group.abc.name
  location            = azurerm_resource_group.abc.location
  pfx_blob            = pkcs12_from_pem.azure-cert.result
  password            = "terraform"
}

resource "azurerm_app_service_certificate_binding" "apps" {
  for_each            = local.public_apps
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.apps[each.value.name].id
  certificate_id      = azurerm_app_service_certificate.cloudflare.id
  ssl_state           = "SniEnabled"
}

# ui-app : vercel

resource "cloudflare_record" "vercel-ui" {
  zone_id = data.cloudflare_zone.abc.id
  name    = "app${local.cname_sufix}"
  value   = "cname.vercel-dns.com"
  type    = "CNAME"
  proxied = false
}

resource "time_sleep" "vercel-dns-timeout" {
  create_duration = "60s"

  triggers = {
    cname = cloudflare_record.vercel-ui.id
  }
}