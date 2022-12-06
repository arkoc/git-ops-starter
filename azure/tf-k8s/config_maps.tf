resource "kubernetes_namespace" "dev-env" {
  metadata {
    annotations = {
      name = "dev"
    }

    name = "dev"
  }
}

resource "kubernetes_namespace" "stage-env" {
  metadata {
    annotations = {
      name = "stage"
    }

    name = "stage"
  }
}

resource "kubernetes_namespace" "prod-env" {
  metadata {
    annotations = {
      name = "prod"
    }

    name = "prod"
  }
}

resource "kubernetes_config_map" "dev-configs" {
  metadata {
    name      = "dev-configs"
    namespace = "dev"
  }

  data = {
    "ConnectionStrings__AppConfig" = data.terraform_remote_state.dev.outputs.deployed_app_config_connection_string
  }
}

resource "kubernetes_config_map" "stage-configs" {
  metadata {
    name      = "stage-configs"
    namespace = "stage"
  }

  data = {
    "ConnectionStrings__AppConfig" = data.terraform_remote_state.stage.outputs.deployed_app_config_connection_string
  }
}

resource "kubernetes_config_map" "prod-configs" {
  metadata {
    name      = "prod-configs"
    namespace = "prod"
  }

  data = {
    "ConnectionStrings__AppConfig" = data.terraform_remote_state.prod.outputs.deployed_app_config_connection_string
  }
}