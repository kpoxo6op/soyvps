# WireGuard Full-Tunnel Setup

## Debian Laptop

1. `sudo apt update && sudo apt install -y wireguard resolvconf`
2. `sudo su`
3. `cd /etc/wireguard && chmod 700 /etc/wireguard`
4. `(umask 077 && wg genkey | tee privatekey | wg pubkey > publickey)`
5. Create `/etc/wireguard/wg0.conf`:

```
[Interface]
Address = 10.8.0.4/24
PrivateKey = <CONTENTS_OF_privatekey>
DNS = 1.1.1.1

[Peer]
PublicKey = <AZURE_VM_PUBLIC_KEY>
Endpoint = <AZURE_VM_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

6. `systemctl enable wg-quick@wg0 && systemctl start wg-quick@wg0`

## Azure VM

1. SSH in: `ssh azureuser@<AZURE_VM_PUBLIC_IP>`
2. `sudo nano /etc/wireguard/wg0.conf`
3. Append:

```
[Peer]
PublicKey = <DEBIAN_LAPTOP_PUBLIC_KEY>
AllowedIPs = 10.8.0.4/32
```

4. `sudo systemctl restart wg-quick@wg0`

## Home Cluster Peer

1. Ensure `[Peer]` pointing to Azure VM includes `AllowedIPs = 10.8.0.0/24, 192.168.1.0/24` if it routes LAN traffic.

## Mobile Phone

1. Create a WireGuard config entry with:

- Address = 10.8.0.2/24
- PrivateKey = <PHONE_PRIVATE_KEY>
- PublicKey (server) = <AZURE_VM_PUBLIC_KEY>
- Endpoint = <AZURE_VM_PUBLIC_IP>:51820
- AllowedIPs = 0.0.0.0/0
- PersistentKeepalive = 25

All traffic from both devices flows through the Azure VM to reach the home cluster and the Internet.
