# ./vm/main.tf - Azure VM resources for WireGuard

resource "azurerm_public_ip" "wireguard_public_ip" {
  name                = "${var.vm_name}-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  # Static to ensure the IP doesn't change on VM restart
  allocation_method   = "Static"
  # Standard SKU is required for availability zones
  sku                 = "Standard"
  
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
    public_key = file(var.ssh_public_key_path)
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
  
  # This cloud-init script prepares the VM for WireGuard by installing pinned
  # package versions for stability, enabling IP forwarding required for VPN 
  # traffic routing, and applying basic security hardening to reduce the 
  # attack surface of the public-facing VPS
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get upgrade -y
    apt-get install -y curl wget htop net-tools
    
    apt-get install -y wireguard=1.0.20210914-1ubuntu2 wireguard-tools=1.0.20210914-1ubuntu2
    
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    
    mkdir -p /etc/wireguard
    chmod 700 /etc/wireguard
    
    hostnamectl set-hostname wireguard-vps
    
    echo "127.0.0.1 wireguard-vps" >> /etc/hosts
    
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF
  )
  
  tags = var.tags
} 