# VM Module

Ubuntu virtual machine for hosting WireGuard VPN server in Azure.

## Architecture

```mermaid
graph TD
    PIP[Public IP<br>Static] --> NIC[Network Interface]
    NIC --> VM[Ubuntu VM<br>Standard_B1s]
    SUBNET[WireGuard Subnet] --> NIC
    SSH[SSH Key<br>Authentication] --> VM
    CUSTOM[Cloud-Init<br>Basic Setup] --> VM
    
    classDef azure fill:#0072C6,color:white
    class PIP,NIC,VM,SUBNET azure
```

## Components

- **Public IP Address**: Static IP for consistent external access
- **Network Interface**: Connected to the specified subnet
- **Ubuntu VM**:
  - Size: Standard_B1s (1 vCPU, 1 GB memory)
  - OS: Ubuntu 22.04 LTS
  - Authentication: SSH key-based only
  - Identity: System-assigned managed identity

## Design Considerations

- **VM Size**: Standard_B1s balances cost and performance for WireGuard workloads
- **OS**: Ubuntu 22.04 LTS provides kernel-level WireGuard support
- **Security**:
  - SSH key authentication with no password access
  - System hardened via cloud-init script
  - Static IP for consistent firewall rules
- **Identity**: Managed identity enables secure Azure resource access

## Configuration

### Required Variables

- `subnet_id`: ID of the subnet where the VM will be deployed
- `ssh_public_key`: SSH public key for VM access authentication

### Usage Example

```hcl
module "vm" {
  source = "./vm"
  
  subnet_id = module.network.wireguard_subnet_id
  ssh_public_key = "ssh-rsa AAAA...your-key...example"
  
  # Optional parameters
  # resource_group_name = "custom-rg"
  # location = "australiaeast"
  # vm_size = "Standard_B2s"
}
```

### Environment Variable

SSH public key can be provided via environment variable:

```bash
export TF_VAR_ssh_public_key="ssh-rsa AAAA...your-key...example"
```

## Initial Configuration

The VM is provisioned with cloud-init that performs:

- System updates and utility installation
- Hostname configuration
- SSH hardening:
  - Root login disabled
  - Password authentication disabled
