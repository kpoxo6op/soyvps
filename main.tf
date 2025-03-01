terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

}

# Simple resource group to test authentication
resource "azurerm_resource_group" "test" {
  name     = "soyvps-test-rg"
  location = "australiaeast"
  
  tags = {
    environment = "test"
    purpose     = "authentication-test"
  }
} 