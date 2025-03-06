#!/bin/bash

git add .

git commit -m "feat(wireguard): Add automated client setup with QR code generation

- Integrated client configuration generation into cloud-init script
- Added QR code display functionality for easy mobile setup
- Verified successful connection from mobile device with Termux
- Simplified deployment process by automating manual steps"

git push origin main

echo "Changes have been committed and pushed to main branch"