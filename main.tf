# /main.tf
#
# EXPLANATION OF THIS FILE:
# 1) Calls the "network" module (already existing in ./network).
# 2) Calls the "vm" module (in ./vm) and passes relevant variables.
# 3) Exposes a few outputs for convenience (public IP, SSH command, etc.).
# 4) No placeholders or partial code—fully working with the existing network module.
#

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

module "network" {
  source = "./network"

  # If needed, override defaults here. Otherwise, rely on network/variables.tf defaults.
  # location            = var.location
  # resource_group_name = var.resource_group_name
  # wireguard_port      = var.wireguard_port
}

module "vm" {
  source = "./vm"

  # Mandatory input: which subnet do we attach the VM NIC to?
  subnet_id = module.network.wireguard_subnet_id

  # Pass in your public SSH key, from root variables or environment. Example:
  ssh_public_key = var.ssh_public_key

  # Optionally override any default VM variables:
  # resource_group_name = module.network.resource_group_name
  # location            = var.location
  # vm_size             = "Standard_B1s"
  # admin_username      = "azureuser"

  # If you want to pass your own pre-generated WG server keys, uncomment these:
  # wg_server_private_key = var.wg_server_private_key
  # wg_server_public_key  = var.wg_server_public_key

  depends_on = [module.network]
}

output "resource_group_name" {
  value       = module.network.resource_group_name
  description = "Resource group name for the network and VM"
}

output "wireguard_subnet_id" {
  value       = module.network.wireguard_subnet_id
  description = "Subnet ID where the VM is placed"
}

output "vm_public_ip" {
  value       = module.vm.public_ip
  description = "Public IP of the WireGuard VM"
}

output "ssh_command" {
  value       = module.vm.ssh_command
  description = "SSH command to connect to the WireGuard VM"
}
