# Verification Plan: WireGuard Server Interface and Firewall Rules

## Task Description

This document outlines the verification steps for configuring the WireGuard server interface (wg0) and establishing proper firewall rules to create a functional VPN endpoint on the Azure VM.

## Implementation Overview

1. Create WireGuard interface configuration with proper IP addressing
2. Configure firewall rules to allow VPN traffic
3. Enable IP forwarding for VPN traffic routing
4. Configure WireGuard service to start automatically on boot
5. Verify the interface is properly functioning

## Verification Process

### PHASE 1: CONFIGURATION IMPLEMENTATION

The implementation will be done through Terraform by updating the cloud-init script in the VM module. This will:

1. Create the WireGuard interface configuration file
2. Configure firewall rules
3. Enable IP forwarding
4. Enable the WireGuard service

### PHASE 2: VERIFICATION ON VPS

After applying the Terraform changes, verify the configuration on the VPS:

1. Verify WireGuard interface configuration:

   ```bash
   # On VPS after Terraform apply
   sudo cat /etc/wireguard/wg0.conf
   ls -la /etc/wireguard/wg0.conf  # Should show 600 permissions
   ```

2. Verify WireGuard service is running:

   ```bash
   # On VPS
   sudo systemctl status wg-quick@wg0
   sudo wg  # Should show active interface
   ```

3. Verify interface is listening on the correct port:

   ```bash
   # On VPS
   sudo ss -tulpn | grep 51820
   ```

4. Verify IP forwarding is enabled:

   ```bash
   # On VPS
   cat /proc/sys/net/ipv4/ip_forward  # Should show '1'
   ```

5. Verify firewall configuration:

   ```bash
   # On VPS
   sudo ufw status  # Should show 51820/udp allowed
   sudo iptables -t nat -L  # Should show MASQUERADE rules
   ```

## Success Criteria

The task is considered successfully completed when:

1. WireGuard interface (wg0) is properly configured with:
   - Correct private key
   - IP address (10.8.0.1/24)
   - Listening on UDP port 51820

2. IP forwarding is enabled to allow VPN traffic routing

3. Firewall rules allow:
   - Inbound traffic on UDP port 51820
   - Forwarding between the WireGuard interface and internet

4. WireGuard service is:
   - Running properly
   - Configured to start automatically on boot

5. Connectivity is working:
   - Interface is accessible via public IP
   - Traffic is properly routed

## Implementation Notes

- The interface will use a private subnet (10.8.0.0/24) for VPN clients
- Server will use the first IP in the range (10.8.0.1)
- Interface will listen on the standard WireGuard port (51820/UDP)
- Configuration will be secured with appropriate file permissions
- Both cloud firewall (NSG) and local firewall (UFW) will be configured
