# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- feat(wireguard): Configure WireGuard interface and firewall rules
  - Implemented WireGuard interface configuration with private network (10.8.0.1/24)
  - Configured proper firewall rules to allow VPN traffic on UDP port 51820
  - Enabled IP forwarding for routing VPN traffic
  - Set up systemd service for automatic WireGuard activation on boot
  - Fixed cloud-init script formatting for proper deployment
  - Added comprehensive verification steps for interface configuration

- feat(wireguard): Implement secure WireGuard key management
  - Created dedicated wireguard system group for controlled access
  - Implemented proper directory and file permissions structure
  - Added automatic key deployment with secure access controls
  - Configured terraform variables with environment variables integration
  - Documented complete key generation and verification process
  - Ensured azureuser can read public key without sudo access

- feat(setup): Initial project setup for Azure VPS with Wireguard
  - Created comprehensive README with installation instructions
  - Added Azure CLI installation and authentication steps
  - Implemented service principal creation and configuration
  - Set up environment variables management with .env files
  - Created basic Terraform configuration for testing authentication

- feat(state): Migrate Terraform state to Azure Storage
  - Configured Azure backend for remote state storage
  - Added state migration instructions with terraform init -migrate-state
  - Documented RBAC and storage account key authentication methods
  - Included verification steps for confirming successful state migration

- feat(network): Implement Azure network infrastructure for WireGuard
  - Created virtual network with dedicated subnet
  - Configured network security groups for WireGuard traffic
  - Added security rules for WireGuard UDP port and SSH access
  - Implemented network module with configurable parameters
  - Added architecture diagrams and documentation

- feat(wireguard): Complete WireGuard installation on Azure VM
  - Successfully installed WireGuard package version 1.0.20210914-1ubuntu2
  - Verified command-line tools and configuration directory accessibility
  - All verification checks passed according to verification plan

### Fixed

- fix(vm): Fix SSH public key configuration for VM
  - Fixed environment variable structure for SSH public key
  - Added required variables to root module level
  - Removed invalid references in output files
  - Validated successful VM creation with Terraform plan
  - Added support for direct SSH public key injection

### Improved

- style: Remove all redundant comments across the codebase
  - Eliminated "AI slop" comments that merely restate resource types
  - Retained only meaningful comments that explain WHY choices were made
  - Added proper file path comments at the top of each file
  - Established clear code commenting rules in documentation
