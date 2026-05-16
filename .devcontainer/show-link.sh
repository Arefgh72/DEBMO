#!/bin/bash

# Get Codespace Name
CS_NAME=$(echo $CODESPACE_NAME)

if [ -z "$CS_NAME" ]; then
    VLESS_HOST="YOUR_CODESPACE_NAME"
    RELAY_URL="https://YOUR_CODESPACE_NAME-8080.app.github.dev"
else
    VLESS_HOST="${CS_NAME}-443.app.github.dev"
    RELAY_URL="https://${CS_NAME}-8080.app.github.dev"
fi

UUID=$(cat .devcontainer/xray_uuid.txt 2>/dev/null || echo "UUID_NOT_FOUND")

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
