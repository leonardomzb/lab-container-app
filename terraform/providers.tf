
terraform {
  required_version = "~> 1.16.4" 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  # Remote backend
  backend "azurerm" {
    resource_group_name  = "rg-storage-lab"
    storage_account_name = "stlabterraformansible"
    container_name       = "bo-lab"
    key                  = "lab.terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}