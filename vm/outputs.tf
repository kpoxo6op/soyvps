# ./vm/outputs.tf - Outputs for the VM module

output "vm_id" {
  description = "The ID of the Ubuntu VM"
  value       = azurerm_linux_virtual_machine.wireguard_vm.id
}

output "vm_name" {
  description = "The name of the Ubuntu VM"
  value       = azurerm_linux_virtual_machine.wireguard_vm.name
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.wireguard_public_ip.ip_address
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.wireguard_nic.private_ip_address
}

output "admin_username" {
  description = "The admin username for the VM"
  value       = var.admin_username
}

output "ssh_command" {
  description = "Command to SSH into the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.wireguard_public_ip.ip_address}"
}

output "vm_identity_principal_id" {
  description = "The Principal ID of the system-assigned identity of the VM"
  value       = azurerm_linux_virtual_machine.wireguard_vm.identity[0].principal_id
} 