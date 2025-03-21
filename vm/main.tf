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
  # - System package installation and security hardening (UFW firewall, SSH hardening)
  # - WireGuard interface configuration with private network (10.8.0.0/24)
  # - Secure key management with appropriate file permissions and group ownership
  # - IP forwarding and NAT configuration for VPN traffic routing
  # - UFW firewall rules to:
  #   - Allow WireGuard VPN traffic (UDP 51820)
  #   - Allow DNS traffic from VPN clients (10.8.0.0/24) to Pihole (192.168.1.122)
  #   - Protect the server from unauthorized access
  # - Automatic WireGuard service activation and persistence
  # - Client configuration generation with Pihole DNS settings
  # - QR code generation for easy mobile client setup
  custom_data = base64encode(<<-EOF
#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install -y curl wget htop net-tools 
apt-get install -y wireguard wireguard-tools qrencode

hostnamectl set-hostname wireguard-vps
echo "127.0.0.1 wireguard-vps" >> /etc/hosts

sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

groupadd -f wireguard
usermod -aG wireguard ${var.admin_username}

mkdir -p /etc/wireguard
chgrp wireguard /etc/wireguard
chmod 750 /etc/wireguard

echo "${var.wg_server_private_key}" > /etc/wireguard/server_private.key
chmod 600 /etc/wireguard/server_private.key

echo "${var.wg_server_public_key}" > /etc/wireguard/server_public.key
chgrp wireguard /etc/wireguard/server_public.key
chmod 644 /etc/wireguard/server_public.key

cat > /etc/wireguard/wg0.conf << WGEOF
[Interface]
PrivateKey = ${var.wg_server_private_key}
Address = 10.8.0.1/24
ListenPort = 51820

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
WGEOF

chmod 600 /etc/wireguard/wg0.conf

echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf

apt-get install -y ufw

ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp
ufw allow 51820/udp
ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto udp
ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto tcp

ufw --force enable

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Setup for client configuration and QR code generation
CLIENT_HOME="/home/${var.admin_username}"
cd $CLIENT_HOME
umask 077
wg genkey | tee client.key | wg pubkey > client.pub

cat > $CLIENT_HOME/client.conf << CLIENT_EOF
[Interface]
Address = 10.8.0.2/24
PrivateKey = $(cat client.key)
DNS = 192.168.1.122

[Peer]
PublicKey = ${var.wg_server_public_key}
Endpoint = $(curl -s ifconfig.me):51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENT_EOF

cat >> /etc/wireguard/wg0.conf << PEER_EOF

# Simple test client
[Peer]
PublicKey = $(cat client.pub)
AllowedIPs = 10.8.0.2/32, 192.168.1.0/24
PEER_EOF

systemctl restart wg-quick@wg0

cat > $CLIENT_HOME/show-qr.sh << SCRIPT_EOF
#!/bin/bash
echo "===================== WIREGUARD QR CODE ======================"
qrencode -t ansiutf8 < $CLIENT_HOME/client.conf
echo "=============================================================="
echo
echo "Scan this QR code with your WireGuard mobile app to connect."
echo "Your client configuration is saved at $CLIENT_HOME/client.conf"
SCRIPT_EOF

chmod +x $CLIENT_HOME/show-qr.sh
chown ${var.admin_username}:${var.admin_username} $CLIENT_HOME/client.key $CLIENT_HOME/client.pub $CLIENT_HOME/client.conf $CLIENT_HOME/show-qr.sh

cat > $CLIENT_HOME/WIREGUARD-README.txt << README_EOF
=================================================================
WIREGUARD VPN SETUP COMPLETE
=================================================================

Your WireGuard VPN server is configured and ready to use.
A client configuration has been automatically created for you.

To display the QR code for mobile app connection:
  $ ./show-qr.sh

Simply scan this QR code with the WireGuard mobile app to connect.

To test connectivity after connecting:
  1. Confirm the status in the WireGuard app shows "Connected"
  2. Try pinging the server's VPN interface: ping 10.8.0.1
  3. If you see successful replies, your WireGuard tunnel is working

Enjoy your secure VPN connection!
=================================================================
README_EOF

chown ${var.admin_username}:${var.admin_username} $CLIENT_HOME/WIREGUARD-README.txt

echo "WireGuard client QR code has been generated."
echo "SSH to the server and run: ./show-qr.sh"
EOF
  )
  
  tags = var.tags
}