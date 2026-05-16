#!/bin/bash

# Ensure we are in the .devcontainer directory
cd "$(dirname "$0")"

# Install Node.js dependencies
if [ ! -f package.json ]; then
    npm init -y
fi
npm install undici

# Set up UUID for Xray if it doesn't exist
if [ ! -f xray_uuid.txt ]; then
    UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
    sed -i "s/PLACEHOLDER_UUID/$UUID/g" config.json
    echo $UUID > xray_uuid.txt
fi

# Ensure scripts are executable
chmod +x start.sh
chmod +x show-link.sh

echo "Setup complete. The start.sh script will now run to start services."
