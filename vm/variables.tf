# ./vm/variables.tf - Variables for WireGuard VM configuration

variable "resource_group_name" {
  description = "Name of the resource group for WireGuard VPS"
  type        = string
  default     = "soyvps-rg"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "newzealandnorth"
}

variable "vm_name" {
  description = "Name of the WireGuard VM"
  type        = string
  default     = "wireguard-vm"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B1s"  # Budget-friendly size sufficient for WireGuard
}

variable "admin_username" {
  description = "Username for the VM admin user"
  type        = string
  default     = "azureuser"
}

variable "subnet_id" {
  description = "ID of the subnet where the VM will be deployed"
  type        = string
}

variable "ubuntu_version" {
  description = "Version of Ubuntu to use"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"  # Ubuntu 22.04 LTS
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "ssh_public_key" {
  description = "SSH public key content for VM authentication"
  type        = string
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 30
}

variable "os_disk_type" {
  description = "Type of OS disk storage"
  type        = string
  default     = "Standard_LRS"  # Standard locally redundant storage (cost-effective)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    environment = "production"
    purpose     = "wireguard-vps"
  }
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key to be used for authentication"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
