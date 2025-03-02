# SoyVPS TODO

## Infrastructure Setup

- [x] Create Azure service principal for Terraform authentication
  > Enables non-interactive Azure automation with proper permissions

- [x] Set up Terraform remote state in Azure Storage
  > Allows team collaboration and consistent state management

- [x] Define Azure network infrastructure in Terraform (VNet, Subnet, NSG)
  > Creates isolated network environment for WireGuard server

- [ ] Create Ubuntu VM in Azure New Zealand North with Terraform
  > Provides stable, public-facing endpoint with static IP

## WireGuard Server Configuration

- [ ] Install WireGuard on Azure VM using Terraform provisioners
  > Sets up VPN server software on our public endpoint

- [ ] Generate WireGuard server keys
  > Creates cryptographic identity for the WireGuard server

- [ ] Configure WireGuard server interface and firewall rules
  > Establishes VPN endpoint with proper network access

- [ ] Create peer configuration for home Kubernetes node
  > Enables home cluster to connect to VPS as a WireGuard client

- [ ] Configure WireGuard to start automatically
  > Ensures VPN server runs persistently, including after reboots

## Routing & Connectivity

- [ ] Set up IP forwarding on VPS
  > Allows traffic to flow between WireGuard clients and server

- [ ] Configure iptables for proper NAT and forwarding
  > Enables traffic to move between internet and VPN tunnel

- [ ] Add monitoring for WireGuard connection status
  > Provides visibility into VPN connectivity state

## Testing & Validation

- [ ] Test WireGuard connections from allowed peers
  > Verifies VPN tunnel works as expected

- [ ] Validate end-to-end connectivity
  > Ensures traffic flows correctly between endpoints

## Documentation

- [ ] Document VPS networking configuration
  > Records design decisions and network layout for future reference

- [ ] Document WireGuard server setup and maintenance
  > Provides operational instructions for ongoing management

- [ ] Create troubleshooting guide
  > Helps diagnose and fix potential connectivity issues
  