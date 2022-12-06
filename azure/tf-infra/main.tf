terraform {

  cloud {
    organization = "abc"
    workspaces {
      name = "dev"
    }
  }

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    tls = {
      source = "hashicorp/tls"
    }
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "3.22.0" # Only this version works
    }
    pkcs12 = {
      source = "chilicat/pkcs12"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
    }
    vercel = {
      source = "vercel/vercel"
    }
    datadog = {
      source = "DataDog/datadog"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "mongodbatlas" {}

provider "azuredevops" {}

provider "cloudflare" {}

provider "vercel" {}

provider "datadog" {}


data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}