#!/bin/bash

# Get Codespace Name
CS_NAME=$(echo $CODESPACE_NAME)

if [ -z "$CS_NAME" ]; then
    echo "Warning: CODESPACE_NAME not found. Make sure you are running in GitHub Codespaces."
    VLESS_HOST="YOUR_CODESPACE_NAME"
    RELAY_URL="https://YOUR_CODESPACE_NAME-8080.app.github.dev"
else
    VLESS_HOST="${CS_NAME}-443.app.github.dev"
    RELAY_URL="https://${CS_NAME}-8080.app.github.dev"
fi

UUID=$(cat .devcontainer/xray_uuid.txt 2>/dev/null || echo "UUID_NOT_FOUND")

VLESS_LINK="vless://${UUID}@${VLESS_HOST}:443?encryption=none&security=none&type=xhttp&mode=packet-up&path=%2F#NikVPN_GAS"

echo "---------------------------------------------------"
echo "NikVPN GAS Relay and VLESS Link"
echo "---------------------------------------------------"
echo ""
echo "VLESS Link (Import this in v2rayNG/Nekobox):"
echo "$VLESS_LINK"
echo ""
echo "GAS Relay URL (Put this in your GAS-cod.Gs file):"
echo "$RELAY_URL"
echo ""
echo "---------------------------------------------------"
echo "To keep Codespace alive, keep the terminal open with:"
echo "tmux attach -t nikvpn"
echo "---------------------------------------------------"
