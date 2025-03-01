# ./network/outputs.tf - Outputs for the network module

output "wireguard_subnet_id" {
  value       = azurerm_subnet.wireguard_subnet.id
  description = "The ID of the subnet where the WireGuard VM will be deployed"
}

output "resource_group_name" {
  value       = azurerm_resource_group.soyvps_rg.name
  description = "The name of the resource group containing the WireGuard VPS resources"
}

output "vnet_id" {
  value       = azurerm_virtual_network.soyvps_vnet.id
  description = "The ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.soyvps_vnet.name
  description = "The name of the virtual network"
}

output "nsg_id" {
  value       = azurerm_network_security_group.wireguard_nsg.id
  description = "The ID of the network security group"
} 