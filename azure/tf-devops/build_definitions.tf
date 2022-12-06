data "terraform_remote_state" "dev" {
  backend = "remote"

  config = {
    organization = "abc"
    workspaces = {
      name = "dev"
    }
  }
}

data "azuredevops_project" "abc" {
  name = "ABC, Inc."
}

locals {
  dev_branch_name              = "dev"
  nuget_suffix                 = "nuget"
  container_suffix             = "container"
  azure_pipeline_templates_dir = "%s-template.yml"
  azure_pipelines_dir          = ".azure/pipelines/%s.yml"
  all_deployable_apps = merge(
    {
      for x in data.terraform_remote_state.dev.outputs.deployable_apps : x.name =>
      {
        name         = x.name,
        type         = x.type,
        yml_template = format(local.azure_pipeline_templates_dir, "${x.type}-${x.stack}")
        repo         = x.repo,
        project_name = split("/", x.repo)[1]
        project_dir  = x.src_project_directory
        url          = x.url
      }
    },
    {
      for y in data.terraform_remote_state.dev.outputs.deployable_packages : y.name =>
      {
        name         = y.name,
        type         = local.nuget_suffix
        yml_template = format(local.azure_pipeline_templates_dir, local.nuget_suffix)
        repo         = y.repo,
        project_name = split("/", y.repo)[1]
        project_dir  = y.src_project_directory
      }
    },
    {
      for y in data.terraform_remote_state.dev.outputs.deployable_containers : y.name =>
      {
        name         = y.name,
        type         = local.container_suffix
        yml_template = format(local.azure_pipeline_templates_dir, local.container_suffix)
        repo         = y.repo,
        project_name = split("/", y.repo)[1]
        image_name   = y.image_name
        project_dir  = y.src_project_directory
      }
  })

  deployments = { for x in local.all_deployable_apps : x.name =>
    {
      name         = x.name,
      repo         = x.repo,
      project_name = x.project_name
      type         = x.type
      image_name   = x.type == local.container_suffix ? x.image_name : null
      yml_path     = format(local.azure_pipelines_dir, "${x.name}_${x.type}")
      project_dir  = x.project_dir
      yml_content = templatefile("${path.module}/templates/azure_devops_template.tftpl",
        {
          template        = x.yml_template
          project_dir     = x.project_dir
          github_endpoint = azuredevops_serviceendpoint_github.pat.service_endpoint_name
      })
    }
  }
}

resource "github_repository_file" "main" {
  for_each            = local.deployments
  repository          = each.value.project_name
  branch              = local.dev_branch_name
  file                = each.value.yml_path
  content             = each.value.yml_content
  commit_message      = "Terraform init azure pipelines for ${each.value.name}"
  commit_author       = "Terraform CI/CD"
  commit_email        = "noreply.terraform.io"
  overwrite_on_create = false

  lifecycle {
    ignore_changes = [
      file,
      content,
      commit_message
    ]
  }
}

resource "azuredevops_build_definition" "build" {
  for_each        = local.deployments
  project_id      = data.azuredevops_project.abc.id
  name            = "${each.value.name} ${each.value.type}"
  path            = join("", ["\\", each.value.project_name])
  agent_pool_name = "build-agents-vmss"

  dynamic "ci_trigger" {
    for_each = each.value.type != local.nuget_suffix ? [1] : []
    content {
      use_yaml = true
    }
  }

  dynamic "ci_trigger" {
    for_each = each.value.type == local.nuget_suffix ? [1] : []
    content {
      override {
        batch = true
        branch_filter {
          include = [local.dev_branch_name]
        }
        path_filter {
          include = [each.value.project_dir]
        }
      }
    }
  }

  repository {
    repo_type             = "GitHub"
    repo_id               = each.value.repo
    branch_name           = "refs/heads/${local.dev_branch_name}"
    yml_path              = each.value.yml_path
    service_connection_id = azuredevops_serviceendpoint_github.pat.id
  }

  variable {
    name  = "AppName"
    value = each.value.name
  }

  variable {
    name  = "ARMServiceEndpoint"
    value = azuredevops_serviceendpoint_azurerm.abc.id
  }

  variable {
    name  = "ACRServiceEndpoint"
    value = azuredevops_serviceendpoint_azurecr.abc.id
  }

  dynamic "variable" {
    for_each = each.value.type == local.container_suffix ? [1] : []
    content {
      name  = "ImageName"
      value = each.value.image_name
    }
  }

  depends_on = [
    github_repository_file.main
  ]
}

locals {
  org_private_repo_name  = ".github-private"
  azure_devops_org_url   = "https://dev.azure.com/abchq/${data.azuredevops_project.abc.name}"
  github_url             = "https://github.com/%s"
  apps_for_github = {
    dev = [
      for x in data.terraform_remote_state.dev.outputs.deployable_apps :
      {
        name             = x.name
        repo             = format(local.github_url, x.repo)
        url              = x.url
        build_status     = "${local.azure_devops_org_url}/_apis/build/status/${split("/", x.repo)[1]}/${x.name}%20${x.type}?repoName=${urlencode(x.repo)}&branchName=dev"
        build_definition = "${local.azure_devops_org_url}/_build/latest?definitionId=${azuredevops_build_definition.build[x.name].id}&repoName=${urlencode(x.repo)}&branchName=dev"
        type             = x.type
      }
    ],
    prod = [
      for x in data.terraform_remote_state.prod.outputs.deployable_apps :
      {
        name             = x.name
        repo             = format(local.github_url, x.repo)
        url              = x.url
        build_status     = "${local.azure_devops_org_url}/_apis/build/status/${split("/", x.repo)[1]}/${x.name}%20${x.type}?repoName=${urlencode(x.repo)}&branchName=main"
        build_definition = "${local.azure_devops_org_url}/_build/latest?definitionId=${azuredevops_build_definition.build[x.name].id}&repoName=${urlencode(x.repo)}&branchName=main"
        type             = x.type
      }
    ]
  }
}

resource "github_repository" "oranization_private" {
  name        = local.org_private_repo_name
  description = "Repository for Organization private README"
  visibility  = "private"
  auto_init   = true
}

resource "github_repository_file" "oranization_private" {
  repository          = github_repository.oranization_private.id
  branch              = "main"
  file                = "profile/README.md"
  content             = templatefile("${path.module}/templates/org_readme.tftpl", local.apps_for_github)
  commit_message      = "Terraform upgrade organization README"
  commit_author       = "Terraform CI/CD"
  commit_email        = "noreply.terraform.io"
  overwrite_on_create = true
}
