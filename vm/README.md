# VM Module for WireGuard VPN Server

This module provisions an Azure VM configured for WireGuard VPN server with secure networking configuration.

## Architecture

```mermaid
graph TD
    PIP[Public IP<br>Static] --> NIC[Network Interface]
    NIC --> VM[Ubuntu VM<br>Standard_B1s]
    SUBNET[WireGuard Subnet] --> NIC
    SSH[SSH Key<br>Authentication] --> VM
    WG[WireGuard<br>Interface] --> VM
    FW[Firewall Rules<br>UFW] --> VM
    NSG[Network Security Group] --> SUBNET
    
    classDef azure fill:#0072C6,color:white
    class PIP,NIC,VM,SUBNET,NSG azure
    classDef security fill:#ff6b6b,color:white
    class SSH,WG,FW security
```

## Network Architecture

```mermaid
graph TD
    subgraph Azure
        NSG[Network Security Group]
        SUBNET[10.0.1.0/24]
        PIP[Public IP]
        VM[WireGuard VM]
    end
    
    subgraph VM Configuration
        WG[WireGuard Interface<br>wg0: 10.8.0.1/24]
        FW[UFW Firewall<br>UDP 51820, TCP 22]
        IPF[IP Forwarding<br>Enabled]
    end
    
    subgraph Client Access
        CLIENT[WireGuard Client<br>10.8.0.2/32]
    end
    
    NSG -->|Allow 51820/UDP| PIP
    NSG -->|Allow 22/TCP| PIP
    PIP --> VM
    VM --> SUBNET
    VM --> WG
    VM --> FW
    VM --> IPF
    CLIENT -->|Encrypted Tunnel| WG
    
    classDef azure fill:#0072C6,color:white
    class NSG,SUBNET,PIP,VM azure
    classDef config fill:#2ecc71,color:white
    class WG,FW,IPF config
    classDef client fill:#f39c12,color:white
    class CLIENT client
```

## Components

- **Public IP Address**: Static IP for consistent external access
- **Network Interface**: Connected to the specified subnet
- **Network Security Group**: Allows traffic on ports 51820/UDP (WireGuard) and 22/TCP (SSH)
- **Ubuntu VM**:
  - Size: Standard_B1s (1 vCPU, 1 GB memory)
  - OS: Ubuntu 22.04 LTS
  - Authentication: SSH key-based only
  - Identity: System-assigned managed identity

## WireGuard Configuration

- **Interface**: wg0 configured with IP address 10.8.0.1/24
- **Port**: Listening on standard WireGuard port 51820/UDP
- **Key Management**: Secure cryptographic keys with proper permissions
- **IP Forwarding**: Enabled for VPN traffic routing
- **Firewall**: Configured with UFW to allow WireGuard and SSH traffic
- **Routing**: PostUp/PostDown rules for proper traffic routing

## WireGuard Key Relationship

WireGuard uses public-key cryptography where:

- Server and client keys are NOT derived from each other - each generates their own independent key pair
- Authentication happens by exchanging public keys (server knows client's public key, client knows server's public key)
- Each side uses their private key + the other's public key to create an encrypted tunnel
- No password exchange occurs - the mathematical relationship between public-private keys enables secure communication

## Design Considerations

- **VM Size**: Standard_B1s balances cost and performance for WireGuard workloads
- **OS**: Ubuntu 22.04 LTS provides kernel-level WireGuard support
- **Security**:
  - SSH key authentication with no password access
  - System hardened via cloud-init script
  - Static IP for consistent firewall rules
  - Restricted WireGuard key permissions
  - Dedicated wireguard system group for key access
- **Network Isolation**:
  - VPN traffic separated on dedicated subnet (10.8.0.0/24)
  - Azure NSG and VM-level firewall for defense in depth
- **Identity**: Managed identity enables secure Azure resource access
- **Persistence**:
  - WireGuard service configured to start on boot
  - IP forwarding configured to persist after reboots
