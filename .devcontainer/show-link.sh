#!/bin/bash

# Get Codespace Name from various possible sources
CS_NAME="$CODESPACE_NAME"

if [ -z "$CS_NAME" ]; then
    # Fallback to hostname if CODESPACE_NAME is not set (sometimes happens in certain shells)
    CS_NAME=$(hostname)
fi

# If it still contains jules or doesn't look like a codespace ID, we try to extract it from the environment
if [[ "$CS_NAME" == *"jules"* ]] || [ -z "$CS_NAME" ]; then
    # In some environments, we can find it via gh command
    if command -v gh &> /dev/null; then
        CS_NAME=$(gh codespace list --json name -q '.[0].name' 2>/dev/null)
    fi
fi

# Final fallback for local testing
if [ -z "$CS_NAME" ]; then
    VLESS_HOST="YOUR_CODESPACE_NAME-443.app.github.dev"
    RELAY_URL="https://YOUR_CODESPACE_NAME-8080.app.github.dev"
else
    VLESS_HOST="${CS_NAME}-443.app.github.dev"
    RELAY_URL="https://${CS_NAME}-8080.app.github.dev"
fi

# Try to find UUID
UUID_FILE=".devcontainer/xray_uuid.txt"
if [ -f "$UUID_FILE" ]; then
    UUID=$(cat "$UUID_FILE")
else
    # Try to find it in config.json if file is missing
    UUID=$(grep -oP '"id": "\K[^"]+' .devcontainer/config.json | head -1)
fi

[ -z "$UUID" ] || [ "$UUID" == "PLACEHOLDER_UUID" ] && UUID="UUID_NOT_READY_YET"

VLESS_LINK="vless://${UUID}@${VLESS_HOST}:443?encryption=none&security=none&type=xhttp&mode=packet-up&path=%2F#NikVPN_GAS"

echo "==================================================="
echo "   NikVPN GAS Relay & VLESS Config Summary"
echo "   Last Updated: $(date)"
echo "==================================================="
echo ""
echo "1. VLESS Link (Import this in v2rayNG/Nekobox):"
echo "---------------------------------------------------"
echo "$VLESS_LINK"
echo "---------------------------------------------------"
echo ""
echo "2. GAS Relay URL (Put this in your GAS-cod.Gs file):"
echo "---------------------------------------------------"
echo "$RELAY_URL"
echo "---------------------------------------------------"
echo ""
echo "3. Status Info:"
echo "---------------------------------------------------"
echo "Ports 443 and 8080 have been set to PUBLIC."
echo "Xray and Relay services are running in 'nikvpn' tmux session."
echo ""
echo "To keep Codespace alive, attach to tmux if possible:"
echo "tmux attach -t nikvpn"
echo "==================================================="
