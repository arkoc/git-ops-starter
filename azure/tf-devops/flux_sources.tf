data "terraform_remote_state" "k8s" {
  backend = "remote"

  config = {
    organization = "abc"
    workspaces = {
      name = "k8s"
    }
  }
}

data "github_repository" "abc-flux" {
  full_name = data.terraform_remote_state.k8s.outputs.flux_repo_full_name
}

locals {
  containers = {
    for x in data.terraform_remote_state.dev.outputs.deployable_containers : x.name =>
    {
      name      = x.name
      full_name = "${data.terraform_remote_state.k8s.outputs.deployed_acr.name}.azurecr.io/${x.name}"
    }
  }
}

resource "github_repository_file" "flux_kustomization" {
  repository          = data.github_repository.abc-flux.id
  branch              = "main"
  file                = "infra/internal-sources/kustomization.yaml"
  content             = templatefile("${path.module}/templates/flux_kustomization_template.tftpl", { containers = local.containers })
  commit_message      = "Terraform update internal Kustomization sources"
  commit_author       = "Terraform CI/CD"
  commit_email        = "noreply.terraform.io"
  overwrite_on_create = true
}

resource "github_repository_file" "flux_images" {
  for_each   = local.containers
  repository = data.github_repository.abc-flux.id
  branch     = "main"
  file       = "infra/internal-sources/${each.value.name}.yaml"
  content = templatefile("${path.module}/templates/flux_image_template.tftpl",
    {
      image_name     = each.value.name
      image_fullName = each.value.full_name
  })
  commit_message      = "Terraform update tracked image sources"
  commit_author       = "Terraform CI/CD"
  commit_email        = "noreply.terraform.io"
  overwrite_on_create = true
}