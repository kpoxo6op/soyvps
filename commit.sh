#!/bin/bash

git add .

git commit -m "feat(wireguard): Configure WireGuard interface and firewall rules
- Implemented WireGuard interface configuration with private network (10.8.0.1/24)
- Configured proper firewall rules to allow VPN traffic on UDP port 51820
- Enabled IP forwarding for routing VPN traffic
- Set up systemd service for automatic WireGuard activation on boot
- Fixed cloud-init script formatting for proper deployment
- Added comprehensive verification steps for interface configuration"

git push origin main

echo "Changes have been committed and pushed to main branch"