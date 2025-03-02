# Ubuntu VM Creation Verification Guide

This guide outlines the steps to verify that the Ubuntu Virtual Machine for the WireGuard VPS has been correctly provisioned in Azure.

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

## SSH Key Configuration

Before applying the Terraform configuration, ensure your SSH key is configured in the .env file:

```bash
# Make sure your SSH public key is in the .env file
grep "TF_VAR_ssh_public_key" .env

# If not present, add it to your .env file
# Example: export TF_VAR_ssh_public_key="ssh-rsa YOUR_KEY_HERE user@example"

# Source your environment variables
source .env

# Verify the environment variable is set
echo $TF_VAR_ssh_public_key | grep -q "ssh-rsa" && echo "SSH key is set" || echo "SSH key is NOT set"
```

## Verify Virtual Machine Creation

```bash
# List all VMs in your resource group
az vm list --resource-group soyvps-rg --output table

# Get detailed information about the WireGuard VM
az vm show --resource-group soyvps-rg --name wireguard-vm

# Verify VM size
az vm show --resource-group soyvps-rg --name wireguard-vm --query "hardwareProfile.vmSize" -o tsv
# Expected: Standard_B1s or similar size depending on configuration

# Verify OS type and image
az vm show --resource-group soyvps-rg --name wireguard-vm --query "storageProfile.imageReference" -o json
# Should show Ubuntu image details
```

## Verify Network Configuration

```bash
# Check if VM is connected to the correct subnet
az vm nic list --resource-group soyvps-rg --vm-name wireguard-vm --query "[].ipConfigurations[].subnet.id" -o tsv
# Should match the subnet ID created in previous step

# Get the VM's private IP address
az vm nic show --resource-group soyvps-rg --vm-name wireguard-vm --nic wireguard-vm-nic --query "ipConfigurations[0].privateIpAddress" -o tsv
# Should be in the 10.0.1.0/24 range

# Get the VM's public IP address
az vm list-ip-addresses --resource-group soyvps-rg --name wireguard-vm --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv
# Should display a public IP address
```

## Verify VM Connectivity

```bash
# Get the public IP address for SSH access
PUBLIC_IP=$(az vm list-ip-addresses --resource-group soyvps-rg --name wireguard-vm --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)

# Test SSH connectivity (will prompt for credentials)
ssh azureuser@$PUBLIC_IP -o ConnectTimeout=5
# Should connect to the VM or time out if SSH service isn't yet running

# Alternative connectivity test without SSH
ping -c 4 $PUBLIC_IP
# Should receive ping responses if ICMP is allowed
```

## Verify VM Status and Extensions

```bash
# Check VM power state
az vm get-instance-view --resource-group soyvps-rg --name wireguard-vm --query "instanceView.statuses[1].displayStatus" -o tsv
# Should display "VM running"

# List any VM extensions
az vm extension list --resource-group soyvps-rg --vm-name wireguard-vm -o table
# Will show any extensions installed (may be empty depending on configuration)
```

## Simple Verification Script

Create a file named `verify-vm.sh` with the following content:

```bash
#!/bin/bash
# Script to verify Azure VM for WireGuard VPS

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Checking Azure login status..."
az account show >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

echo -n "Verifying VM exists... "
VM_ID=$(az vm show --resource-group soyvps-rg --name wireguard-vm --query id -o tsv 2>/dev/null)
if [ -z "$VM_ID" ]; then
  echo -e "${RED}❌ VM not found!${NC}"
  exit 1
else
  echo -e "${GREEN}✅ VM exists${NC}"
  
  echo -n "Checking VM power state... "
  VM_STATE=$(az vm get-instance-view --resource-group soyvps-rg --name wireguard-vm --query "instanceView.statuses[1].displayStatus" -o tsv)
  if [[ "$VM_STATE" == *"running"* ]]; then
    echo -e "${GREEN}✅ VM is running${NC}"
  else
    echo -e "${RED}❌ VM is not running (State: $VM_STATE)${NC}"
  fi
  
  echo -n "Checking OS type... "
  OS_TYPE=$(az vm show --resource-group soyvps-rg --name wireguard-vm --query "storageProfile.osDisk.osType" -o tsv)
  if [[ "$OS_TYPE" == "Linux" ]]; then
    echo -e "${GREEN}✅ OS Type is Linux${NC}"
  else
    echo -e "${RED}❌ Unexpected OS Type: $OS_TYPE${NC}"
  fi
  
  echo -n "Checking public IP assignment... "
  PUBLIC_IP=$(az vm list-ip-addresses --resource-group soyvps-rg --name wireguard-vm --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)
  if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}❌ No public IP assigned!${NC}"
  else
    echo -e "${GREEN}✅ Public IP: $PUBLIC_IP${NC}"
  fi
  
  echo -n "Verifying network connection to correct subnet... "
  SUBNET_ID=$(az vm nic list --resource-group soyvps-rg --vm-name wireguard-vm --query "[].ipConfigurations[].subnet.id" -o tsv)
  if [[ "$SUBNET_ID" == *"wireguard-subnet"* ]]; then
    echo -e "${GREEN}✅ Connected to WireGuard subnet${NC}"
  else
    echo -e "${RED}❌ Not connected to expected subnet!${NC}"
  fi
  
  echo -e "\nTo test SSH connectivity (when ready):"
  echo -e "  ssh azureuser@$PUBLIC_IP"
fi
```

Make the script executable and run it:

```bash
chmod +x verify-vm.sh
./verify-vm.sh
```

## Terraform State Verification

You can also verify the VM through Terraform:

```bash
# Show resources in Terraform state
terraform state list | grep -E 'vm|publicip'

# View details of the VM in Terraform state
terraform state show azurerm_linux_virtual_machine.wireguard_vm

# Run plan to verify no drift
terraform plan -detailed-exitcode
```

After successful verification, you'll have a stable Ubuntu VM with a static public IP address, ready for WireGuard installation. 