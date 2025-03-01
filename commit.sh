#!/bin/bash

git add .
git commit -m "feat(network): Implement Azure network infrastructure in Terraform (pending verification)
- Created virtual network and subnet for WireGuard VPS
- Configured network security group with rules for WireGuard and SSH
- Implemented modular Terraform structure for network components
- Added verification tools for network infrastructure
- Marked task as pending verification in TODO.md"
git push origin main 