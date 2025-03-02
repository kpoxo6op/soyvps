# ./main.tf - Root Terraform configuration for WireGuard VPS

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

resource "azurerm_resource_group" "test" {
  name     = "soyvps-test-rg"
  location = "australiaeast"
  
  tags = {
    environment = "test"
    purpose     = "authentication-test"
  }
} 

module "network" {
  source = "./network"
  
  # Optionally override default variables
  # location = "newzealandnorth"
  # resource_group_name = "soyvps-rg"
  # vnet_address_space = ["10.0.0.0/16"]
  # subnet_address_prefix = ["10.0.1.0/24"]
  # wireguard_port = 51820
}

module "vm" {
  source = "./vm"
  
  # Pass the subnet ID from the network module
  subnet_id = module.network.wireguard_subnet_id
  
  # Pass the SSH public key from environment variable
  ssh_public_key = var.ssh_public_key
  
  # Optionally override default variables
  # resource_group_name = module.network.resource_group_name
  # location = "newzealandnorth"
  # vm_size = "Standard_B1s"
  # admin_username = "azureuser"
  
  depends_on = [module.network]
}

output "resource_group_name" {
  value = module.network.resource_group_name
  description = "The name of the resource group for WireGuard VPS"
}

output "wireguard_subnet_id" {
  value = module.network.wireguard_subnet_id
  description = "The ID of the subnet where the WireGuard VM will be deployed"
}

output "vm_public_ip" {
  value = module.vm.public_ip_address
  description = "The public IP address of the WireGuard VM"
}

output "ssh_command" {
  value = module.vm.ssh_command
  description = "Command to SSH into the WireGuard VM"
} 