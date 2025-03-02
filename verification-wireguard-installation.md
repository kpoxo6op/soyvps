# Verification Plan: WireGuard Installation on Azure VM

## Task Description

Install WireGuard on Azure VM using cloud-init to set up the VPN server software on the public endpoint.

## Verification Method

Human verification via SSH and command-line checks.

## Verification Steps

1. **Check cloud-init logs for installation status**:

   ```bash
   # View the cloud-init output log to confirm successful installation
   sudo cat /var/log/cloud-init-output.log | grep -i wireguard
   
   # Check for any errors in the cloud-init log
   sudo cat /var/log/cloud-init-output.log | grep -i error
   ```

2. **Verify WireGuard is installed correctly**:

   ```bash
   # Check if WireGuard kernel module is loaded
   lsmod | grep wireguard
   
   # Verify WireGuard package is installed with correct version
   apt list --installed | grep wireguard
   
   # Confirm the specific versions are installed (1.0.20210914-1ubuntu2)
   dpkg -l | grep wireguard
   ```

3. **Verify WireGuard tools are available**:

   ```bash
   # Check if WireGuard tools are installed and working
   wg --version
   
   # Check if WireGuard utilities are present
   which wg
   which wg-quick
   ```

4. **Verify WireGuard can be configured**:

   ```bash
   # Check that the WireGuard configuration directory exists
   ls -la /etc/wireguard/
   
   # Verify we can access it with proper permissions
   sudo touch /etc/wireguard/test.txt && sudo rm /etc/wireguard/test.txt
   ```

## Expected Results

1. Cloud-init logs should show successful installation of the WireGuard packages
2. WireGuard package should be listed as installed with version 1.0.20210914-1ubuntu2
3. WireGuard command-line tools should be available and functional
4. The WireGuard configuration directory should exist and be accessible with the correct permissions (700)

## Implementation Approach

The implementation uses cloud-init to:

1. Install the WireGuard package using the system's package manager with pinned version 1.0.20210914-1ubuntu2
2. Set up IP forwarding required for routing VPN traffic
3. Create and secure the WireGuard configuration directory
4. Configure basic system security hardening

This verification will validate that WireGuard is properly installed and ready for configuration in the next tasks.
