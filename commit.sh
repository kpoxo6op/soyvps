#!/bin/bash

git add .

git commit -m "feat(decommission): archive repository after migrating to Tailscale

- Destroyed all Azure infrastructure (VM, networking, storage)
- Removed Terraform state and monitoring resources  
- Updated README with decommission notice and cleanup status
- Final cost: $0.00/month (all resources removed)
- Migration reason: Switched to Tailscale for VPN access"

git push origin main

echo "Repository has been decommissioned and archived"