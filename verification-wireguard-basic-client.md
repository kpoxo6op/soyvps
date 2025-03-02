# Verification Plan: WireGuard Basic Client Access Test

## Task Description

This document outlines the steps to create and verify a minimal WireGuard client configuration to test connectivity to our VPN server. This basic verification ensures the WireGuard server is properly set up before implementing more complex peer configurations.

## Visual Overview

### WireGuard Key Relationship

```mermaid
graph LR
    subgraph "Server Side"
        SPriv["Server Private Key<br>(SECRET)"] --> SPub["Server Public Key"]
    end
    
    subgraph "Client Side"
        CPriv["Client Private Key<br>(SECRET)"] --> CPub["Client Public Key"]
    end
    
    SPub -->|"Added to client<br>config"| CConfig["Client Config File"]
    CPub -->|"Added to server<br>config"| SConfig["Server Config File"]
    
    classDef secret fill:#f9a, stroke:#333, stroke-width:2px
    classDef public fill:#af6, stroke:#333, stroke-width:1px
    classDef config fill:#adf, stroke:#333, stroke-width:1px
    
    class SPriv,CPriv secret
    class SPub,CPub public
    class SConfig,CConfig config
```

### Network Topology

```mermaid
graph TD
    Internet((Internet)) --- ServerPublicIP["Azure VM<br>Public IP"]
    
    subgraph "Azure VPS"
        ServerPublicIP --- WG["WireGuard Interface<br>wg0: 10.8.0.1/24"]
    end
    
    subgraph "Your Windows PC"
        Client["WireGuard Client<br>10.8.0.2/24"]
    end
    
    WG <-->|"Encrypted UDP Tunnel<br>Port 51820"| Client
    
    classDef azure fill:#0072C6, color:white
    classDef client fill:#5CB85C, color:white
    classDef vpn fill:#5BC0DE, color:white
    
    class ServerPublicIP azure
    class Client client
    class WG vpn
```

### Connection Flow

```mermaid
sequenceDiagram
    participant PC as Your Windows PC
    participant VM as Azure VM (10.8.0.1)
    
    Note over PC,VM: Phase 1: Generate Keys
    PC->>PC: Generate client keypair
    
    Note over PC,VM: Phase 2: Server Configuration
    PC->>VM: SSH to server
    PC->>VM: Add client public key to server config
    VM->>VM: Restart WireGuard service
    
    Note over PC,VM: Phase 3: Client Configuration
    PC->>PC: Create client config with server public key
    
    Note over PC,VM: Phase 4: Testing Connection
    PC->>VM: WireGuard connects (UDP 51820)
    PC->>VM: Ping 10.8.0.1
    VM-->>PC: Ping reply
    
    Note over PC,VM: Success! Tunnel is working!
```

## Implementation Overview

1. Generate a test client key pair
2. Add a client peer configuration to the WireGuard server
3. Create a local client configuration file
4. Test basic connectivity through the VPN

## Step-by-Step Process

### PHASE 1: CLIENT KEY GENERATION (Run on your HOME PC)

1. Generate a test client key pair:

   ```bash
   # On HOME PC
   # Generate client private key
   wg genkey > wireguard_client_private.key
   
   # Generate client public key from private key
   wg pubkey < wireguard_client_private.key > wireguard_client_public.key
   
   # View keys (for configuration purposes)
   echo "Client private key: $(cat wireguard_client_private.key)"
   echo "Client public key: $(cat wireguard_client_public.key)"
   ```

### PHASE 2: SERVER PEER CONFIGURATION (Run on your VPS)

1. SSH into the VPS:

   ```bash
   ssh azureuser@<vps-ip-address>
   ```

2. Add client as a peer to the WireGuard server configuration:

   ```bash
   # On VPS
   # Backup the current config
   sudo cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup
   
   # Add the client peer to the configuration
   sudo tee -a /etc/wireguard/wg0.conf << EOF
   
   # Test Client
   [Peer]
   PublicKey = $(cat wireguard_client_public.key)  # Replace with your client public key
   AllowedIPs = 10.8.0.2/32
   EOF
   
   # Restart the WireGuard interface to apply changes
   sudo systemctl restart wg-quick@wg0
   
   # Verify the peer was added
   sudo wg show
   ```

### PHASE 3: CLIENT CONFIGURATION (Run on your HOME PC)

1. Make sure you're using the correct server public key from your environment:

   ```bash
   # On HOME PC
   # First, ensure your environment variables are loaded
   source .env
   
   # Verify you can see the server public key
   echo $TF_VAR_wg_server_public_key
   
   # This should match the public key on the server
   # You can verify with:
   ssh azureuser@<vps-ip-address> "cat /etc/wireguard/server_public.key"
   ```

2. Create a client configuration file with the exact keys:

   ```bash
   # On HOME PC
   # Create a basic client configuration
   cat > wg-client.conf << EOF
   [Interface]
   PrivateKey = $(cat wireguard_client_private.key)
   Address = 10.8.0.2/24
   DNS = 1.1.1.1, 8.8.8.8
   
   [Peer]
   PublicKey = $TF_VAR_wg_server_public_key
   Endpoint = <vps-ip-address>:51820
   AllowedIPs = 10.8.0.0/24
   PersistentKeepalive = 25
   EOF
   
   # Verify the configuration has the correct keys
   cat wg-client.conf
   ```

3. Securely clean up the key files (optional if kept for testing):

   ```bash
   # On HOME PC - Only do this after saving the client config
   shred -u wireguard_client_private.key
   shred -u wireguard_client_public.key
   ```

### PHASE 4: CONNECTIVITY TESTING USING WINDOWS CLIENT

1. Install the WireGuard client for Windows:
   - Download the installer from [https://www.wireguard.com/install/](https://www.wireguard.com/install/)
   - Run the installer and follow the prompts

2. Import the configuration:
   - Open the WireGuard client application
   - Click the "Import tunnel(s) from file" button
   - Select your `wg-client.conf` file
   - Alternatively, you can drag and drop the file into the WireGuard window

3. Connect and verify:
   - Click the "Activate" button to connect to the VPN
   - The status should change to "Active" with a green background
   - Open a command prompt and test connectivity:

     ```cmd
     ping 10.8.0.1
     ```

   - You should see successful ping responses from the server

4. Check the connection details:
   - Click the "Edit" button to view the connection details
   - Verify the configuration matches what you expect
   - The log tab may provide useful information for troubleshooting

5. Disconnect when done testing:
   - Click the "Deactivate" button to disconnect from the VPN

### Configuration File Overview

```mermaid
graph TD
    subgraph "Server Config: /etc/wireguard/wg0.conf"
        SInt["[Interface]<br>PrivateKey = SERVER_PRIVATE_KEY<br>Address = 10.8.0.1/24<br>ListenPort = 51820"]
        SPeer["[Peer] - Client<br>PublicKey = CLIENT_PUBLIC_KEY<br>AllowedIPs = 10.8.0.2/32"]
    end
    
    subgraph "Client Config: wg-client.conf"
        CInt["[Interface]<br>PrivateKey = CLIENT_PRIVATE_KEY<br>Address = 10.8.0.2/24<br>DNS = 1.1.1.1, 8.8.8.8"]
        CPeer["[Peer] - Server<br>PublicKey = SERVER_PUBLIC_KEY<br>Endpoint = VPS-IP:51820<br>AllowedIPs = 10.8.0.0/24<br>PersistentKeepalive = 25"]
    end
    
    classDef serverConfig fill:#d9edf7, stroke:#31708f, stroke-width:1px
    classDef clientConfig fill:#dff0d8, stroke:#3c763d, stroke-width:1px
    
    class SInt,SPeer serverConfig
    class CInt,CPeer clientConfig
```

## Success Criteria

The task is considered successful when:

1. Client key pair is successfully generated
2. Server configuration correctly includes the client peer
3. Client configuration properly references the server public key from your environment variables
4. WireGuard Windows client successfully connects to the server
5. Ping works from the client to the server (10.8.0.1)
6. The WireGuard interface (10.8.0.2) is properly configured on the client

## Notes

- This is a minimal configuration for testing purposes only
- The WireGuard Windows client installation is required
- The client has only a single IP (10.8.0.2/32) without additional access
- For a production scenario, consider configuring proper routing rules
- Client configuration should be stored securely as it contains the private key
- We're using the exact same server public key that's already deployed to the VPS via Terraform
