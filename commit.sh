#!/bin/bash

git add .
git commit -m "fix(vm): Fix SSH public key configuration and variable setup

- Fixed environment variable structure for SSH key
- Added ssh_public_key variable at root module level
- Removed tls_public_key_path references from outputs
- Successfully validated VM creation with terraform plan
- Simplified SSH key configuration for better usability"
git push origin main 