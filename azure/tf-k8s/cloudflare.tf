data "cloudflare_zone" "abc" {
  name = "abc.cloud"
}

resource "cloudflare_record" "gateway-private" {
  zone_id = data.cloudflare_zone.abc.id
  name    = "*.k8s-internal"
  value   = local.app_gateway_private_ip
  type    = "A"
  proxied = false
}

resource "cloudflare_record" "gateway-public" {
  zone_id = data.cloudflare_zone.abc.id
  name    = "*.k8s"
  value   = azurerm_public_ip.app_gateway.ip_address
  type    = "A"
  proxied = false
}