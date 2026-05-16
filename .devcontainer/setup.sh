#!/bin/bash

# Navigate to the root directory of the repository
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Install Node.js dependencies at root
if [ ! -f package.json ]; then
    npm init -y
fi
npm install undici

# Set up UUID for Xray if it doesn't exist
if [ ! -f .devcontainer/xray_uuid.txt ]; then
    UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen)
    sed -i "s/PLACEHOLDER_UUID/$UUID/g" .devcontainer/config.json
    echo $UUID > .devcontainer/xray_uuid.txt
fi

# Ensure scripts are executable
chmod +x .devcontainer/start.sh
chmod +x .devcontainer/show-link.sh

echo "Setup complete. The start.sh script will now run to start services."
