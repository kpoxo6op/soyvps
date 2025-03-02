# ./vm/main.tf - Azure VM resources for WireGuard

resource "azurerm_public_ip" "wireguard_public_ip" {
  name                = "${var.vm_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"  # Static to ensure the IP doesn't change on VM restart
  sku                 = "Standard"  # Standard SKU is required for availability zones
  
  tags = var.tags
}

resource "azurerm_network_interface" "wireguard_nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wireguard_public_ip.id
  }
  
  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "wireguard_vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.wireguard_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.ubuntu_version.publisher
    offer     = var.ubuntu_version.offer
    sku       = var.ubuntu_version.sku
    version   = var.ubuntu_version.version
  }

  identity {
    type = "SystemAssigned"
  }
  
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Update and install basic utilities
    apt-get update
    apt-get upgrade -y
    apt-get install -y curl wget htop net-tools
    
    # Set hostname
    hostnamectl set-hostname wireguard-vps
    
    # Add to /etc/hosts
    echo "127.0.0.1 wireguard-vps" >> /etc/hosts
    
    # Basic hardening
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF
  )
  
  tags = var.tags
} 