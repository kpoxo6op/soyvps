# SoyVPS

A project to manage VPS for Wireguard access to home Kubernetes cluster via Terraform in Azure New Zealand North region.

## Getting Started

### Prerequisites

- Linux/Ubuntu environment
- Terraform (latest version recommended)
- Azure CLI

### Installing Terraform on WSL

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update && sudo apt install -y terraform

# Verify installation
terraform --version
```

### Installing Azure CLI

Run the following commands to install Azure CLI:

```bash
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt update && sudo apt install -y azure-cli
```

Verify the installation:

```bash
az version
```

### Azure Authentication

Login to your Azure account using device code authentication:

```bash
az login --use-device-code
```

You will see output similar to:

```text
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code PWY4TAX9N to authenticate.

Retrieving tenants and subscriptions for the selection...

[Tenant and subscription selection]

No     Subscription name     Subscription ID                       Tenant
-----  --------------------  ------------------------------------  -----------------
[1] *  Azure subscription 1  208d3103-eb6c-4f40-9eaf-f340166c1587  Default Directory
```

### Create Service Principal

```bash
az ad sp create-for-rbac --name "SoyVPS-Terraform" --role Contributor --scope /subscriptions/$(az account show --query id -o tsv)
```

Output:

```text
{
  "appId": "5....................................1",
  "displayName": "SoyVPS-Terraform",
  "password": "5....................................d",
  "tenant": "c......................................5"
}
```

**Important:** Save the password immediately as it cannot be retrieved later. This is the only time the password is displayed.

To view the service principal details later (note that this doesn't show the password):

```bash
az ad sp list --display-name "SoyVPS-Terraform"
```

### Configure Terraform with Service Principal

1. Create a `.env.sample` file:

```bash
# .env.sample - Template for environment variables (DO NOT add real credentials here)
ARM_CLIENT_ID=your_client_id
ARM_CLIENT_SECRET=your_client_secret
ARM_SUBSCRIPTION_ID=your_subscription_id
ARM_TENANT_ID=your_tenant_id
```

2. Create your actual `.env` file with real credentials (this file should be in .gitignore):

```bash
# .env - KEEP THIS FILE PRIVATE, DO NOT COMMIT TO GIT
ARM_CLIENT_ID=5..................................1
ARM_CLIENT_SECRET=5......................................d
ARM_SUBSCRIPTION_ID=2..................................7
ARM_TENANT_ID=c..................................5
```

3. Load the environment variables before running Terraform:

```bash
source .env
terraform init
terraform plan
```
