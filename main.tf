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

# WireGuard VPS Network Infrastructure
module "network" {
  source = "./network"
  
  # Optionally override default variables
  # location = "newzealandnorth"
  # resource_group_name = "soyvps-rg"
  # vnet_address_space = ["10.0.0.0/16"]
  # subnet_address_prefix = ["10.0.1.0/24"]
  # wireguard_port = 51820
}

# Export network outputs
output "resource_group_name" {
  value = module.network.resource_group_name
  description = "The name of the resource group for WireGuard VPS"
}

output "wireguard_subnet_id" {
  value = module.network.wireguard_subnet_id
  description = "The ID of the subnet where the WireGuard VM will be deployed"
} 