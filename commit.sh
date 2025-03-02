#!/bin/bash

git add .
git commit -m "feat(vm): Complete VM creation and verification

- Successfully created Ubuntu VM in Azure New Zealand North
- Verified SSH access to the VM with public key authentication
- Marked VM creation task as complete in TODO.md
- Added verification section to VM README with SSH instructions
- VM is running Ubuntu 22.04.5 LTS with system-assigned managed identity
- Public static IP is allocated and accessible"
git push origin main 