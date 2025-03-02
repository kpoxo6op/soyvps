# Verification Plan: WireGuard Server Keys Generation

## Task Description

This document outlines the verification steps for ensuring WireGuard server keys are correctly generated, securely stored locally in .env files, and properly deployed to the VPS through Terraform.

## Implementation Overview

1. Generate WireGuard keys once on local PC
2. Store keys in local .env file and password manager
3. Configure Terraform to read keys from environment variables
4. Terraform deploys these same keys to each new VPS instance

## Step-by-Step Process

### PHASE 1: LOCAL KEY GENERATION (Run on your HOME PC)

1. Install WireGuard tools locally if not already present:

   ```bash
   # On HOME PC
   sudo apt-get update
   sudo apt-get install wireguard-tools
   ```

2. Generate keys locally (one-time operation):

   ```bash
   # On HOME PC
   # Generate private key
   wg genkey > wireguard_server_private.key
   
   # Generate public key from private key
   wg pubkey < wireguard_server_private.key > wireguard_server_public.key
   ```

3. View and store keys in password manager:

   ```bash
   # On HOME PC
   echo "Private key: $(cat wireguard_server_private.key)"
   echo "Public key: $(cat wireguard_server_public.key)"
   # Copy these values to your password manager
   ```

4. Add to .env file:

   ```bash
   # On HOME PC
   echo "WG_SERVER_PRIVATE_KEY=$(cat wireguard_server_private.key)" >> .env
   echo "WG_SERVER_PUBLIC_KEY=$(cat wireguard_server_public.key)" >> .env
   ```

5. Secure the original key files:

   ```bash
   # On HOME PC
   shred -u wireguard_server_private.key
   shred -u wireguard_server_public.key
   ```

6. Add .env to .gitignore:

   ```bash
   # On HOME PC
   echo ".env" >> .gitignore
   ```

### PHASE 2: TERRAFORM CONFIGURATION (Run on your HOME PC)

1. Create or modify Terraform variables in your project:

   ```terraform
   # In variables.tf on HOME PC
   variable "wg_server_private_key" {
     description = "WireGuard server private key"
     type        = string
     sensitive   = true
   }

   variable "wg_server_public_key" {
     description = "WireGuard server public key"
     type        = string
   }
   ```

2. Verify Terraform can access environment variables:

   ```bash
   # On HOME PC
   source .env
   terraform console
   > var.wg_server_private_key
   > var.wg_server_public_key
   ```

3. Ensure your Terraform code deploys these keys to the VPS:

   ```terraform
   here must be cloud init echoes with mostly masked keys
   ```

### PHASE 3: VERIFICATION ON VPS (Run on your VPS after deployment)

1. Verify key files existence on server:

   ```bash
   # On VPS after Terraform apply
   ls -la /etc/wireguard/
   ```

2. Verify key file permissions:

   ```bash
   # On VPS
   stat -c "%a %n" /etc/wireguard/server_private.key
   stat -c "%a %n" /etc/wireguard/server_public.key
   ```

3. Verify key validity:

   ```bash
   # On VPS
   wg pubkey < /etc/wireguard/server_private.key | diff - /etc/wireguard/server_public.key
   ```

### PHASE 4: CROSS-VERIFICATION (Comparing HOME PC and VPS)

1. Verify key consistency between local and remote:

   ```bash
   # On HOME PC
   source .env
   echo $WG_SERVER_PUBLIC_KEY
   
   # On VPS (in a separate terminal)
   cat /etc/wireguard/server_public.key
   ```

   Compare the outputs manually to ensure they match.

## Success Criteria

The task is considered successfully completed when:

1. Keys are successfully generated and stored on HOME PC
2. Keys are securely stored in password manager for backup
3. Terraform can successfully read the keys from environment variables
4. The keys are correctly deployed to the VPS
5. Server keys match the locally generated keys
6. File permissions are properly set on VPS to maintain security

## Notes

- The private key should never be displayed in logs or shared
- The public key will be needed later for peer configuration
- These keys form the cryptographic identity of the WireGuard server
- Since the VPS will be rebuilt multiple times, reusing the same keys maintains a consistent server identity
- The .env file must be excluded from version control via .gitignore
