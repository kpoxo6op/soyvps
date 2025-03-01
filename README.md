# SoyVPS

A project to manage VPS for Wireguard access to home Kubernetes cluster via Terraform in Azure New Zealand North region.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
  - [Service Principal Setup](#service-principal-setup)
  - [Environment Variables](#environment-variables)
- [State Management](#state-management)
  - [Setting Up Remote State](#setting-up-remote-state)
  - [Access Methods](#access-methods)
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

Create a service principal for Terraform to use:

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac --name "SoyVPS-Terraform" --role Contributor --scope /subscriptions/$(az account show --query id -o tsv)

# Output will include:
# {
#   "appId": "your-client-id",
#   "displayName": "SoyVPS-Terraform",
#   "password": "your-client-secret",
#   "tenant": "your-tenant-id"
# }
```

### Environment Variables

Create a `.env` file with your credentials (add to .gitignore):

```bash
# Terraform Azure authentication variables
export ARM_CLIENT_ID=your-client-id
export ARM_CLIENT_SECRET=your-client-secret
export ARM_SUBSCRIPTION_ID=your-subscription-id
export ARM_TENANT_ID=your-tenant-id
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

### Access Methods

You can access Azure Storage using either storage account keys or RBAC:

#### Storage Account Key (Traditional)

```bash
# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group tfstate-rg --account-name soyvpstfstate --query '[0].value' -o tsv)

# Add to environment variables
export ARM_ACCESS_KEY=$ACCOUNT_KEY

# Access storage via key
az storage blob list \
  --container-name tfstate \
  --account-name soyvpstfstate \
  --account-key $ACCOUNT_KEY \
  --query "[].name"
```

#### RBAC (Modern Approach)

```bash
# Get your user ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Assign Storage Blob Data Contributor role
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $USER_ID \
  --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/tfstate-rg/providers/Microsoft.Storage/storageAccounts/soyvpstfstate"

# Access storage via RBAC (after role propagation)
az storage blob list \
  --container-name tfstate \
  --account-name soyvpstfstate \
  --auth-mode login \
  --query "[].name"
```

### Verifying State

To verify Terraform state migration:

```bash
# Initialize with backend (use either ARM_ACCESS_KEY or RBAC)
source .env
terraform init -migrate-state

# List resources in state
terraform state list

# Using Azure CLI with RBAC
az storage blob list \
  --container-name tfstate \
  --account-name soyvpstfstate \
  --auth-mode login \
  --query "[].name"

# Download state file
az storage blob download \
  --container-name tfstate \
  --name terraform.tfstate \
  --account-name soyvpstfstate \
  --auth-mode login \
  --file downloaded-state.json
```
