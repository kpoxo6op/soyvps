# /vm/outputs.tf
#
# EXPLANATION OF THIS FILE:
# 1) Provides outputs for the VM’s public IP and an SSH command example.
# 2) If needed, you can also output the private IP, or the generated WG keys, etc.
#

output "public_ip" {
  description = "Public IP of the WireGuard VM"
  value       = azurerm_public_ip.wireguard_public_ip.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.wireguard_public_ip.ip_address}"
}
