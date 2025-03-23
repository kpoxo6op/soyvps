########################################
# This Terraform configuration deploys:
#
# 1) A Resource Group, Virtual Network, Subnet, and Network Security Group (NSG).
#    - The NSG opens inbound SSH (TCP/22) from anywhere and WireGuard (UDP/51820).
#    - The NSG is associated with the subnet so traffic can reach the VM.
#
# 2) A VM running Ubuntu on Azure.
#    - It uses an SSH public key for admin login (azureuser).
#    - The VM is assigned a public IP so you can SSH from your home PC.
#
# 3) Cloud-init (custom_data) bootstraps WireGuard on the VM:
#    - Generates server & client keypairs (in Terraform) and writes them to the VM.
#    - Enables IPv4 forwarding and sets up NAT (masquerade) on the VM's primary interface.
#    - Configures UFW to:
#         * Allow SSH (22/tcp).
#         * Allow WireGuard (51820/udp).
#         * Allow VPN clients (10.8.0.0/24) to access DNS on 192.168.1.122 (both tcp/udp 53).
#         * Allow forwarding so VPN clients can reach the internet and your home Pi-hole.
#    - Creates /etc/wireguard/wg0.conf with server IP 10.8.0.1/24.
#    - Creates a test client configuration with AllowedIPs=0.0.0.0/0 and DNS=192.168.1.122,
#      so mobile traffic goes through the VPN and uses your home cluster DNS (.122).
#
# 4) When complete:
#    - You can SSH to the VM public IP (port 22).
#    - You can install the WG client config on your phone and connect:
#         * The phone’s public traffic goes out via the VPS (full tunnel).
#         * DNS to your home cluster at 192.168.1.122.
#    - The VM will forward and NAT traffic from wg0 to the internet or your local services.
########################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.61.0"  # or any version you trust
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

########################################################
#  Variables
########################################################

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "soyvps-rg"
}

variable "vnet_name" {
  type    = string
  default = "soyvps-vnet"
}

variable "subnet_name" {
  type    = string
  default = "wireguard-subnet"
}

variable "nsg_name" {
  type    = string
  default = "wireguard-nsg"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "wireguard_port" {
  type    = number
  default = 51820
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "admin_public_ssh_key" {
  type    = string
  # Replace this with your real SSH public key. This is just an example key.
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9fB7tQJwN+Yq+zZQ3EXAMPLEz4EG8u azureuser@example"
}

########################################################
#  Generate WireGuard Keypairs for Server & Client
########################################################

resource "tls_private_key" "wg_server" {
  algorithm = "ed25519"
}

resource "tls_private_key" "wg_client" {
  algorithm = "ed25519"
}

########################################################
#  Resource Group, VNet, Subnet, NSG
########################################################

resource "azurerm_resource_group" "soyvps_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "soyvps_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  location            = azurerm_resource_group.soyvps_rg.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "wireguard_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.soyvps_rg.name
  virtual_network_name = azurerm_virtual_network.soyvps_vnet.name
  address_prefixes     = var.subnet_address_prefix
}

resource "azurerm_network_security_group" "wireguard_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.soyvps_rg.location
  resource_group_name = azurerm_resource_group.soyvps_rg.name
}

resource "azurerm_network_security_rule" "allow_wireguard" {
  name                        = "AllowWireGuard"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = var.wireguard_port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.wireguard_nsg.name
  resource_group_name         = azurerm_resource_group.soyvps_rg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "AllowSSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.wireguard_nsg.name
  resource_group_name         = azurerm_resource_group.soyvps_rg.name
}

resource "azurerm_subnet_network_security_group_association" "wireguard_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.wireguard_subnet.id
  network_security_group_id = azurerm_network_security_group.wireguard_nsg.id
}

########################################################
#  Public IP + Network Interface
########################################################

resource "azurerm_public_ip" "wireguard_public_ip" {
  name                = "wireguard-vm-ip"
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  location            = azurerm_resource_group.soyvps_rg.location
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "wireguard_nic" {
  name                = "wireguard-vm-nic"
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  location            = azurerm_resource_group.soyvps_rg.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.wireguard_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wireguard_public_ip.id
  }
}

########################################################
#  Linux VM with Cloud-init for WireGuard
########################################################

resource "azurerm_linux_virtual_machine" "wireguard_vm" {
  name                = "wireguard-vm"
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  location            = azurerm_resource_group.soyvps_rg.location
  size                = var.vm_size
  admin_username      = "azureuser"

  admin_ssh_key {
    username       = "azureuser"
    public_key     = var.admin_public_ssh_key
  }

  network_interface_ids = [
    azurerm_network_interface.wireguard_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(
    <<-EOF
      #!/usr/bin/env bash

      # Update packages
      apt-get update -y
      apt-get install -y wireguard qrencode ufw

      # Enable IP forwarding
      echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
      sysctl -w net.ipv4.ip_forward=1

      # Detect primary network interface for NAT
      PRIMARY_IF=$(ip route get 8.8.8.8 | grep -oP '(?<=dev )\\S+')

      # Set up NAT (masquerade) so VPN clients can reach the Internet / local network
      iptables -t nat -A POSTROUTING -o $PRIMARY_IF -j MASQUERADE
      # Make it persist across reboots
      apt-get install -y iptables-persistent
      netfilter-persistent save
      netfilter-persistent reload

      # Create WireGuard server keys
      mkdir -p /etc/wireguard
      echo "${tls_private_key.wg_server.private_key_pem}" > /etc/wireguard/server.key
      chmod 600 /etc/wireguard/server.key
      echo "${tls_private_key.wg_server.public_key_openssh}" > /etc/wireguard/server.pub
      chmod 644 /etc/wireguard/server.pub

      # Create WireGuard client keys (test client)
      echo "${tls_private_key.wg_client.private_key_pem}" > /etc/wireguard/client.key
      chmod 600 /etc/wireguard/client.key
      echo "${tls_private_key.wg_client.public_key_openssh}" > /etc/wireguard/client.pub
      chmod 644 /etc/wireguard/client.pub

      # WireGuard interface config for the server
      cat <<WG_CONF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.8.0.1/24
SaveConfig = false
ListenPort = ${var.wireguard_port}
PrivateKey = \$(cat /etc/wireguard/server.key)
PostUp   = ufw allow in on wg0
PostDown = ufw delete allow in on wg0
WG_CONF

      # Bring up wg0
      systemctl enable wg-quick@wg0
      systemctl start wg-quick@wg0

      # Configure UFW firewall
      ufw default deny incoming
      ufw default allow outgoing

      # Allow SSH and WireGuard ports
      ufw allow 22/tcp
      ufw allow ${var.wireguard_port}/udp

      # Allow DNS to your home cluster Pi-hole at 192.168.1.122 from VPN clients
      ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto udp
      ufw allow in on wg0 from 10.8.0.0/24 to 192.168.1.122 port 53 proto tcp

      # Allow forwarding so VPN clients can reach local network and internet
      ufw allow forward

      # Enable UFW
      ufw --force enable

      # Append the test client as a peer on the server
      cat >> /etc/wireguard/wg0.conf <<PEER_EOF

[Peer]
PublicKey = \$(cat /etc/wireguard/client.pub)
AllowedIPs = 10.8.0.2/32
PEER_EOF

      # Restart WG to load the peer
      systemctl restart wg-quick@wg0

      # Generate a sample client config
      cat <<CLIENT_EOF > /etc/wireguard/client.conf
[Interface]
Address = 10.8.0.2/24
PrivateKey = \$(cat /etc/wireguard/client.key)
DNS = 192.168.1.122

[Peer]
PublicKey = \$(cat /etc/wireguard/server.pub)
Endpoint = \$(curl -s ifconfig.co):${var.wireguard_port}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
CLIENT_EOF

      # Show the client config QR code on console (for quick phone config)
      echo "Client config file: /etc/wireguard/client.conf"
      qrencode -t ansiutf8 < /etc/wireguard/client.conf

      # Done
      echo "WireGuard setup complete."
    EOF
  )

  tags = {
    environment = "production"
    purpose     = "wireguard-vps"
  }
}

########################################################
#  Outputs
########################################################

output "vm_public_ip" {
  description = "Public IP of the WireGuard VM"
  value       = azurerm_public_ip.wireguard_public_ip.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh azureuser@${azurerm_public_ip.wireguard_public_ip.ip_address}"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.soyvps_rg.name
}

output "subnet_id" {
  description = "ID of the WireGuard subnet"
  value       = azurerm_subnet.wireguard_subnet.id
}

output "server_private_key" {
  description = "Server private key (for reference). Do NOT store in version control!"
  value       = tls_private_key.wg_server.private_key_pem
  sensitive   = true
}

output "server_public_key" {
  description = "Server public key"
  value       = tls_private_key.wg_server.public_key_openssh
}

output "client_private_key" {
  description = "Client private key (for reference). Do NOT store in version control!"
  value       = tls_private_key.wg_client.private_key_pem
  sensitive   = true
}

output "client_public_key" {
  description = "Client public key"
  value       = tls_private_key.wg_client.public_key_openssh
}
