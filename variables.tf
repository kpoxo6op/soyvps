# ./variables.tf - Variables for SoyVPS Terraform configuration

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "newzealandnorth"
}

variable "resource_group_name" {
  description = "Name of the resource group for WireGuard VPS"
  type        = string
  default     = "soyvps-rg"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "soyvps-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet for WireGuard server"
  type        = string
  default     = "wireguard-subnet"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the WireGuard subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "nsg_name" {
  description = "Name of the network security group"
  type        = string
  default     = "wireguard-nsg"
}

variable "wireguard_port" {
  description = "UDP port for WireGuard VPN service"
  type        = number
  default     = 51820
}

variable "ssh_public_key" {
  description = "SSH public key content for VM authentication"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    environment = "production"
    purpose     = "wireguard-vps"
  }
}

variable "wg_server_private_key" {
  description = "WireGuard server private key"
  type        = string
  sensitive   = true
}

variable "wg_server_public_key" {
  description = "WireGuard server public key"
  type        = string
} 