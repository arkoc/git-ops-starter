resource "kubernetes_namespace" "cert_manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.id
  version    = "1.10"

  create_namespace = false

  set {
    name  = "installCRDs"
    value = "true"
  }

}

resource "time_sleep" "wait" {
  create_duration = "60s"

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_secret" "cloudflare-api-token-secret" {
  metadata {
    name      = "cloudflare-api-token-secret"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_cert_manager_token
  }

  type = "Opaque"
}

resource "kubectl_manifest" "cluster_issuer" {

  validate_schema = false

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cert-manager"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "devops@abc.io"
        privateKeySecretRef = {
          name = "cert-manager-private-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = "cloudflare-api-token-secret"
                key  = "api-token"
              }
            }
          }
        }]
      }
    }
  })

  depends_on = [kubernetes_namespace.cert_manager, helm_release.cert_manager, time_sleep.wait, kubernetes_secret.cloudflare-api-token-secret]
}