#!/bin/bash

git add .
git commit -m "feat(network): Complete Azure network infrastructure in Terraform
- Created virtual network and subnet for WireGuard VPS
- Configured network security group with rules for WireGuard and SSH
- Implemented modular Terraform structure for network components
- Added architectural diagrams for network visualization
- Verified infrastructure using Azure CLI commands"
git push origin main 