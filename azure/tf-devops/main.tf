terraform {

  cloud {
    organization = "abc"
    workspaces {
      name = "devops"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "0.2.2"
    }
    github = {
      source  = "integrations/github"
      version = "5.3.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "github" {
  owner = "abc"
}

provider "azuredevops" {}

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {}