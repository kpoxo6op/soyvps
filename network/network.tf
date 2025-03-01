# ./network/network.tf - Azure network infrastructure for WireGuard VPS

# Resource group for production resources
resource "azurerm_resource_group" "soyvps_rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "soyvps_vnet" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  location            = azurerm_resource_group.soyvps_rg.location
  address_space       = var.vnet_address_space
  
  tags = var.tags
}

# Subnet for WireGuard server
resource "azurerm_subnet" "wireguard_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.soyvps_rg.name
  virtual_network_name = azurerm_virtual_network.soyvps_vnet.name
  address_prefixes     = var.subnet_address_prefix
}

# Network Security Group
resource "azurerm_network_security_group" "wireguard_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.soyvps_rg.location
  resource_group_name = azurerm_resource_group.soyvps_rg.name
  
  tags = var.tags
}

# NSG Rule for WireGuard
resource "azurerm_network_security_rule" "allow_wireguard" {
  name                        = "AllowWireGuard"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = tostring(var.wireguard_port)
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.soyvps_rg.name
  network_security_group_name = azurerm_network_security_group.wireguard_nsg.name
}

# NSG Rule for SSH access
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
  resource_group_name         = azurerm_resource_group.soyvps_rg.name
  network_security_group_name = azurerm_network_security_group.wireguard_nsg.name
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "wireguard_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.wireguard_subnet.id
  network_security_group_id = azurerm_network_security_group.wireguard_nsg.id
} 