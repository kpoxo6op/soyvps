# Network Infrastructure Verification Guide

This guide contains commands to verify that the Azure network infrastructure for the WireGuard VPS has been correctly provisioned.

## Prerequisites

Ensure you have the Azure CLI installed and are logged in:

```bash
# Verify Azure CLI is installed
az --version

# Login to Azure (if not already logged in)
az login --use-device-code

# Verify correct subscription is selected
az account show
```

## Verify Virtual Network (VNet)

```bash
# List all VNets in your resource group
az network vnet list --resource-group soyvps-rg --output table

# Get detailed information about the WireGuard VNet
az network vnet show --resource-group soyvps-rg --name soyvps-vnet

# Verify address space
az network vnet show --resource-group soyvps-rg --name soyvps-vnet --query "addressSpace.addressPrefixes" -o tsv
```

## Verify Subnet Configuration

```bash
# List all subnets in the VNet
az network vnet subnet list --resource-group soyvps-rg --vnet-name soyvps-vnet --output table

# Get detailed information about the WireGuard subnet
az network vnet subnet show --resource-group soyvps-rg --vnet-name soyvps-vnet --name wireguard-subnet

# Verify subnet address range
az network vnet subnet show --resource-group soyvps-rg --vnet-name soyvps-vnet --name wireguard-subnet --query "addressPrefix" -o tsv
```

## Verify Network Security Group (NSG)

```bash
# List all NSGs in your resource group
az network nsg list --resource-group soyvps-rg --output table

# Get detailed information about the WireGuard NSG
az network nsg show --resource-group soyvps-rg --name wireguard-nsg

# List all security rules in the NSG
az network nsg rule list --resource-group soyvps-rg --nsg-name wireguard-nsg --output table
```

## Verify NSG Rules for WireGuard

```bash
# Check for the WireGuard UDP port rule (default port 51820)
az network nsg rule show --resource-group soyvps-rg --nsg-name wireguard-nsg --name AllowWireGuard

# Check for SSH access rule (for administration)
az network nsg rule show --resource-group soyvps-rg --nsg-name wireguard-nsg --name AllowSSH

# Check that default subnet is associated with the NSG
az network vnet subnet show --resource-group soyvps-rg --vnet-name soyvps-vnet --name wireguard-subnet --query "networkSecurityGroup.id" -o tsv
```

## Verify Infrastructure with Terraform

```bash
# Perform a Terraform plan to verify no drift
terraform plan -detailed-exitcode

# Show the current Terraform state for network components
terraform state list | grep -E 'vnet|subnet|nsg'

# Get details about a specific resource
terraform state show azurerm_virtual_network.soyvps_vnet
terraform state show azurerm_subnet.wireguard_subnet
terraform state show azurerm_network_security_group.wireguard_nsg
```

## Simple Verification Script

Create a file named `verify-network.sh` with the following content:

```bash
#!/bin/bash
# Script to verify Azure network infrastructure for WireGuard VPS

echo "Checking Azure login status..."
az account show >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

echo "Verifying resource group exists..."
RG_EXISTS=$(az group exists --name soyvps-rg)
if [ "$RG_EXISTS" != "true" ]; then
  echo "❌ Resource group soyvps-rg does not exist!"
  exit 1
fi
echo "✅ Resource group soyvps-rg exists"

echo "Verifying VNet..."
VNET_ID=$(az network vnet show --resource-group soyvps-rg --name soyvps-vnet --query id -o tsv 2>/dev/null)
if [ -z "$VNET_ID" ]; then
  echo "❌ VNet soyvps-vnet does not exist!"
else
  echo "✅ VNet soyvps-vnet exists"
  
  echo "Verifying subnet..."
  SUBNET_ID=$(az network vnet subnet show --resource-group soyvps-rg --vnet-name soyvps-vnet --name wireguard-subnet --query id -o tsv 2>/dev/null)
  if [ -z "$SUBNET_ID" ]; then
    echo "❌ Subnet wireguard-subnet does not exist!"
  else
    echo "✅ Subnet wireguard-subnet exists"
  fi
  
  echo "Verifying NSG..."
  NSG_ID=$(az network nsg show --resource-group soyvps-rg --name wireguard-nsg --query id -o tsv 2>/dev/null)
  if [ -z "$NSG_ID" ]; then
    echo "❌ NSG wireguard-nsg does not exist!"
  else
    echo "✅ NSG wireguard-nsg exists"
    
    echo "Checking WireGuard port rule..."
    WG_RULE=$(az network nsg rule show --resource-group soyvps-rg --nsg-name wireguard-nsg --name AllowWireGuard --query name -o tsv 2>/dev/null)
    if [ -z "$WG_RULE" ]; then
      echo "❌ WireGuard port rule does not exist!"
    else
      echo "✅ WireGuard port rule exists"
    fi
  fi
fi
```

Make the script executable and run it:

```bash
chmod +x verify-network.sh
./verify-network.sh
``` 