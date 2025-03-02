#!/bin/bash

git add .
git commit -m "fix(vm): Fix SSH key configuration and improve module documentation

- Fixed environment variable structure for SSH key
- Added ssh_public_key variable at root module level
- Removed tls_public_key_path references from outputs
- Successfully validated VM creation with terraform plan
- Updated both network and VM READMEs to be more declarative
- Simplified documentation to focus on what the modules are, not what they will be"
git push origin main 