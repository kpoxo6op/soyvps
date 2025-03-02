# SoyVPS

A project to manage VPS for Wireguard access to home Kubernetes cluster via Terraform in Azure New Zealand North region.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
  - [Service Principal Setup](#service-principal-setup)
  - [Environment Variables](#environment-variables)
- [State Management](#state-management)
  - [Setting Up Remote State](#setting-up-remote-state)
  - [RBAC Access Setup](#rbac-access-setup)
  - [Verifying State](#verifying-state)

## Prerequisites

```bash
# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Install Azure CLI
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt update && sudo apt install -y azure-cli

# Login to Azure
az login --use-device-code
```

## Authentication

### Service Principal Setup

Create a service principal for Terraform:

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac --name "SoyVPS-Terraform" --role Contributor --scope /subscriptions/$(az account show --query id -o tsv)

# Note the output values:
# - appId (ARM_CLIENT_ID)
# - password (ARM_CLIENT_SECRET)
# - tenant (ARM_TENANT_ID)
# - subscription ID (ARM_SUBSCRIPTION_ID)
```

### Environment Variables

Create a `.env` file with credentials (add to .gitignore):

```bash
# Terraform Azure authentication variables
export ARM_CLIENT_ID=client-id-value
export ARM_CLIENT_SECRET=client-secret-value
export ARM_SUBSCRIPTION_ID=subscription-id-value
export ARM_TENANT_ID=tenant-id-value

# SSH public key for VM authentication
export TF_VAR_ssh_public_key="ssh-rsa YOUR_SSH_PUBLIC_KEY_HERE user@example"
```

Before running Terraform commands, source your environment variables:

```bash
source .env
terraform init
terraform plan
```

To verify your SSH key is set correctly:

```bash
echo $TF_VAR_ssh_public_key | grep -q "ssh-rsa" && echo "SSH key is set" || echo "SSH key is NOT set"
```

## State Management

### Setting Up Remote State

```bash
# Create resource group
az group create --name tfstate-rg --location newzealandnorth

# Create storage account
az storage account create --resource-group tfstate-rg \
  --name soyvpstfstate \
  --sku Standard_LRS \
  --encryption-services blob \
  --location newzealandnorth

# Create blob container
az storage container create \
  --name tfstate \
  --account-name soyvpstfstate
```

Create a backend configuration file:

```bash
cat > backend.tf << 'EOF'
terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "soyvpstfstate"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}
EOF
```

### RBAC Access Setup

Set up RBAC for Azure Storage access:

```bash
# Get user ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $USER_ID \
  --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/soyvpstfstate"

# Wait 5-10 minutes for role propagation
```

### Verifying State

Verify Terraform state migration:

```bash
# Initialize with backend 
source .env
terraform init -migrate-state

# List resources in state
terraform state list

# Verify blob using Azure CLI with RBAC
az storage blob list \
  --container-name tfstate \
  --account-name soyvpstfstate \
  --auth-mode login \
  --query "[].name"

# Download state file for inspection
az storage blob download \
  --container-name tfstate \
  --name terraform.tfstate \
  --account-name soyvpstfstate \
  --auth-mode login \
  --file downloaded-state.json
```
