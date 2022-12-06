# SSH
locals {
  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# Flux
data "flux_install" "main" {
  target_path      = "main-cluster"
  components_extra = ["image-reflector-controller", "image-automation-controller"]
}

data "flux_sync" "main" {
  target_path = "main-cluster"
  url         = "ssh://git@github.com/${var.github_owner}/${var.flux_repository_name}.git"
  branch      = "main"
}

# Kubernetes
resource "kubernetes_namespace" "flux_system" {
  metadata {
    name = "flux-system"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].labels,
    ]
  }
}

data "kubectl_file_documents" "install" {
  content = data.flux_install.main.content
}

data "kubectl_file_documents" "sync" {
  content = data.flux_sync.main.content
}

locals {
  install = [for v in data.kubectl_file_documents.install.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
  sync = [for v in data.kubectl_file_documents.sync.documents : {
    data : yamldecode(v)
    content : v
    }
  ]
}

resource "kubectl_manifest" "install" {
  for_each   = { for v in local.install : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubectl_manifest" "sync" {
  for_each   = { for v in local.sync : lower(join("/", compact([v.data.apiVersion, v.data.kind, lookup(v.data.metadata, "namespace", ""), v.data.metadata.name]))) => v.content }
  depends_on = [kubernetes_namespace.flux_system]
  yaml_body  = each.value
}

resource "kubernetes_secret" "main" {
  depends_on = [kubectl_manifest.install]

  metadata {
    name      = data.flux_sync.main.secret
    namespace = data.flux_sync.main.namespace
  }

  data = {
    identity       = tls_private_key.flux.private_key_pem
    "identity.pub" = tls_private_key.flux.public_key_pem
    known_hosts    = local.known_hosts
  }
}

# GitHub
resource "github_repository" "flux" {
  name       = var.flux_repository_name
  visibility = "private"
  auto_init  = true
}

resource "github_branch_default" "flux" {
  repository = github_repository.flux.name
  branch     = "main"
}

resource "github_repository_deploy_key" "main" {
  title      = "main-cluster"
  repository = github_repository.flux.name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = false
}

resource "github_repository_file" "install" {
  repository = github_repository.flux.name
  file       = data.flux_install.main.path
  content    = data.flux_install.main.content
  branch     = "main"
}

resource "github_repository_file" "sync" {
  repository = github_repository.flux.name
  file       = data.flux_sync.main.path
  content    = data.flux_sync.main.content
  branch     = "main"
}

resource "github_repository_file" "kustomize" {
  repository = github_repository.flux.name
  file       = data.flux_sync.main.kustomize_path
  content    = data.flux_sync.main.kustomize_content
  branch     = "main"
}

resource "kubernetes_secret" "flux-webhook" {
  metadata {
    name      = "flux-discord-webhook-url"
    namespace = data.flux_sync.main.namespace
  }

  data = {
    address = var.flux_notification_webhook
  }

  depends_on = [kubectl_manifest.install]
}

locals {
  flux_discord_provider_name = "discord-flux"
}

resource "kubectl_manifest" "flux-discord-notificaiton" {

  validate_schema = false

  yaml_body = yamlencode({
    apiVersion = "notification.toolkit.fluxcd.io/v1beta1"
    kind       = "Provider"
    metadata = {
      name      = local.flux_discord_provider_name
      namespace = data.flux_sync.main.namespace
    }
    spec = {
      type = "discord"
      secretRef = {
        name = kubernetes_secret.flux-webhook.metadata[0].name
      }
    }
  })

  depends_on = [kubernetes_secret.flux-webhook, kubectl_manifest.install]
}

resource "kubectl_manifest" "flux-discord-notificaiton-alert" {

  validate_schema = false

  yaml_body = yamlencode({
    apiVersion = "notification.toolkit.fluxcd.io/v1beta1"
    kind       = "Alert"
    metadata = {
      name      = "discord-flux-alert"
      namespace = data.flux_sync.main.namespace
    }
    spec = {
      summary = "Main Cluster notifications"
      providerRef = {
        name = local.flux_discord_provider_name
      }
      eventSeverity = "info"
      eventSources = [
        {
          kind = "GitRepository"
          name = "*"
        },
        {
          kind = "HelmRelease"
          name = "*"
        },
        {
          kind = "HelmChart"
          name = "*"
        },
        {
          kind = "Kustomization"
          name = "*"
        },
        {
          kind = "ImageUpdateAutomation"
          name = "*"
        }
      ]
    }
  })

  depends_on = [kubectl_manifest.flux-discord-notificaiton]
}

resource "kubernetes_secret" "acr-secret" {
  metadata {
    name      = "regcred"
    namespace = data.flux_sync.main.namespace
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${azurerm_container_registry.abc.login_server}" = {
          "username" = azurerm_container_registry.abc.admin_username
          "password" = azurerm_container_registry.abc.admin_password
          "auth"     = base64encode("${azurerm_container_registry.abc.admin_username}:${azurerm_container_registry.abc.admin_password}")
        }
      }
    })
  }
}