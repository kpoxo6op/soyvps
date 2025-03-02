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
  
  # This cloud-init script configures the WireGuard VPN server with proper security measures.
  # It implements:
  # - System package installation and security hardening
  # - WireGuard interface configuration with private network (10.8.0.0/24)
  # - Secure key management with appropriate permissions
  # - IP forwarding for VPN traffic routing
  # - Firewall rules to allow VPN traffic and protect the server
  # - Automatic service activation for persistent operation
  custom_data = base64encode(<<-EOF
#!/bin/bash

# SYSTEM PREPARATION
apt-get update
apt-get upgrade -y
apt-get install -y curl wget htop net-tools

apt-get install -y wireguard wireguard-tools

# SYSTEM SECURITY CONFIGURATION
hostnamectl set-hostname wireguard-vps
echo "127.0.0.1 wireguard-vps" >> /etc/hosts

sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# WIREGUARD GROUP SETUP
groupadd -f wireguard
usermod -aG wireguard ${var.admin_username}

mkdir -p /etc/wireguard
chgrp wireguard /etc/wireguard
chmod 750 /etc/wireguard

# WIREGUARD KEYS SETUP
echo "${var.wg_server_private_key}" > /etc/wireguard/server_private.key
chmod 600 /etc/wireguard/server_private.key

echo "${var.wg_server_public_key}" > /etc/wireguard/server_public.key
chgrp wireguard /etc/wireguard/server_public.key
chmod 644 /etc/wireguard/server_public.key

# WIREGUARD INTERFACE CONFIGURATION
cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = ${var.wg_server_private_key}
Address = 10.8.0.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
WGEOF

chmod 600 /etc/wireguard/wg0.conf

# IP FORWARDING CONFIGURATION
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf

# FIREWALL CONFIGURATION
apt-get install -y ufw

ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp
ufw allow 51820/udp

ufw --force enable

# ENABLE WIREGUARD SERVICE
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
EOF
  )
  
  tags = var.tags
}