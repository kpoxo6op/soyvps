# /vm/variables.tf
#
# EXPLANATION OF THIS FILE:
# 1) Holds input variables specifically for the VM module (WireGuard VM).
# 2) References them in vm/main.tf (like resource_group_name, subnet_id, etc.).
# 3) If you already have some in the root-level variables, you can pass them in from main.tf.
#

variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group for this VM"
  default     = "soyvps-rg"
}

variable "location" {
  type        = string
  description = "Azure location"
  default     = "newzealandnorth"
}

variable "vm_name" {
  type        = string
  description = "Name of the WireGuard VM"
  default     = "wireguard-vm"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size"
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to allow for login"
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the WireGuard VM NIC will be attached"
}

variable "wireguard_port" {
  type        = number
  description = "UDP port for WireGuard"
  default     = 51820
}

variable "os_disk_size_gb" {
  type        = number
  description = "OS disk size in GB"
  default     = 30
}

variable "os_disk_type" {
  type        = string
  description = "OS disk SKU type"
  default     = "Standard_LRS"
}

variable "ubuntu_version" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Image reference for the Ubuntu OS"
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags for the VM"
  default     = {
    environment = "production"
    purpose     = "wireguard-vps"
  }
}

variable "wg_server_private_key" {
  type        = string
  description = "Optional: Pre-generated WG server private key"
  sensitive   = true
  default     = ""
}

variable "wg_server_public_key" {
  type        = string
  description = "Optional: Pre-generated WG server public key"
  default     = ""
}
