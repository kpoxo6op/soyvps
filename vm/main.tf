# /vm/main.tf
#
# EXPLANATION OF THIS FILE:
# 1) Creates a Public IP + NIC + Ubuntu VM in Azure using Terraform.
# 2) Installs and configures WireGuard via a cloud-init (custom_data) script:
#    - Server and test-client keys are generated if not explicitly passed in.
#    - IP forwarding + NAT is set up for full-tunnel VPN.
#    - UFW is configured to allow SSH (22/tcp), WireGuard (udp/51820),
#      DNS queries to Pi-hole at 192.168.1.122, and forwarding of VPN traffic.
#    - The test client config has AllowedIPs=0.0.0.0/0 + DNS=192.168.1.122
#      so your mobile phone uses Pi-hole DNS and routes all traffic via the VPS.
# 3) Exposes outputs for the public IP and an SSH command string.
#

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#########################
# Optional: Generate WireGuard keys in Terraform
# If you prefer to supply your own keys, set them via variables
# wg_server_private_key / wg_server_public_key
#########################

# Only create these if user didn't supply them from outside
resource "tls_private_key" "wg_server" {
  count = var.wg_server_private_key == "" ? 1 : 0
  algorithm = "ed25519"
}

resource "tls_private_key" "wg_client" {
  algorithm = "ed25519"
}

#########################
# Public IP & NIC
#########################

resource "azurerm_public_ip" "wireguard_public_ip" {
  name                = "wireguard-vm-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "wireguard_nic" {
  name                = "wireguard-vm-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wireguard_public_ip.id
  }
}

#########################
# Ubuntu VM
#########################

resource "azurerm_linux_virtual_machine" "wireguard_vm" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [
    azurerm_network_interface.wireguard_nic.id
  ]

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

  # Cloud-init script sets up WireGuard with Pi-hole DNS, NAT, UFW rules, etc.
  custom_data = base64encode(<<-EOF
#!/usr/bin/env bash

# Update system
apt-get update -y
apt-get install -y wireguard qrencode ufw

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.ip_forward=1

# Identify primary NIC for NAT
PRIMARY_IF=\$(ip route get 8.8.8.8 | grep -oP '(?<=dev )\\S+')

# Set up NAT for wg0
iptables -t nat -A POSTROUTING -o \$PRIMARY_IF -j MASQUERADE
apt-get install -y iptables-persistent
netfilter-persistent save
netfilter-persistent reload

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# If user didn't supply server keys, use the ones from tls_private_key
# Otherwise, use var.wg_server_private_key
if [ "${var.wg_server_private_key}" = "" ]; then
  echo "${tls_private_key.wg_server.private_key_pem}" > /etc/wireguard/server.key
  echo "${tls_private_key.wg_server.public_key_openssh}" > /etc/wireguard/server.pub
else
  echo "${var.wg_server_private_key}" > /etc/wireguard/server.key
  echo "${var.wg_server_public_key}"  > /etc/wireguard/server.pub
fi
chmod 600 /etc/wireguard/server.key
chmod 644 /etc/wireguard/server.pub

# Always use the generated client key
echo "${tls_private_key.wg_client.private_key_pem}" > /etc/wireguard/client.key
echo "${tls_private_key.wg_client.public_key_openssh}" > /etc/wireguard/client.pub
chmod 600 /etc/wireguard/client.key
chmod 644 /etc/wireguard/client.pub

# Server config
cat <<WG_CONF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.8.0.1/24
SaveConfig = false
ListenPort = ${var.wireguard_port}
PrivateKey = \$(cat /etc/wireguard/server.key)
PostUp   = ufw allow in on wg0
PostDown = ufw delete allow in on wg0
WG_CONF

# Enable & start
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# UFW firewall config
ufw default deny incoming
ufw default allow outgoing

# Allow SSH + WG
ufw allow 22/tcp
ufw allow ${var.wireguard_port}/udp

# Pi-hole DNS on 192.168.1.122 from VPN clients
ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto udp
ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto tcp

# Forwarding
ufw allow forward

ufw --force enable

# Add test client peer
cat >> /etc/wireguard/wg0.conf <<PEER_EOF

[Peer]
PublicKey = \$(cat /etc/wireguard/client.pub)
AllowedIPs = 10.8.0.2/32
PEER_EOF

systemctl restart wg-quick@wg0

# Generate a sample client config w/ Pi-hole DNS
cat <<CLIENT_EOF > /etc/wireguard/client.conf
[Interface]
Address = 10.8.0.2/24
PrivateKey = \$(cat /etc/wireguard/client.key)
DNS = 192.168.1.122

[Peer]
PublicKey = \$(cat /etc/wireguard/server.pub)
Endpoint = \$(curl -s ifconfig.me):${var.wireguard_port}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENT_EOF

echo "Client config: /etc/wireguard/client.conf"
qrencode -t ansiutf8 < /etc/wireguard/client.conf
echo "WireGuard setup complete."
  EOF)
  
  tags = var.tags
}
