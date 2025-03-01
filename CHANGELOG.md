# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

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