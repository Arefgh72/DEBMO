#!/bin/bash

# Install Node.js dependencies
cd .devcontainer
npm init -y
npm install undici

# Set up UUID for Xray
UUID=$(cat /proc/sys/kernel/random/uuid)
sed -i "s/PLACEHOLDER_UUID/$UUID/g" config.json
echo $UUID > xray_uuid.txt

# Create start script shortcut
chmod +x start.sh
chmod +x show-link.sh

echo "Setup complete. Please run .devcontainer/start.sh to begin."
