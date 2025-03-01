#!/bin/bash

git add .
git commit -m "feat(state): Migrate Terraform state to Azure Storage

- Configured Azure backend for remote state storage
- Added state migration instructions with terraform init -migrate-state
- Documented RBAC and storage account key authentication methods
- Included verification steps for confirming successful state migration

Updated CHANGELOG.md with the state migration entry."
git push origin main 