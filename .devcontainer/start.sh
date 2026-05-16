#!/bin/bash

# Navigate to the root directory
cd "$(dirname "$0")/.."

# Kill existing tmux session if it exists
tmux kill-session -t nikvpn 2>/dev/null

# Start a new tmux session
tmux new-session -d -s nikvpn

# Run Xray in the first pane
tmux send-keys -t nikvpn "xray -c .devcontainer/config.json" C-m

# Split the pane and run the Node.js relay
tmux split-window -h -t nikvpn
tmux send-keys -t nikvpn "node .devcontainer/relay.js" C-m

echo "Xray and GAS Relay started in tmux session 'nikvpn'."

# Wait a few seconds for services to initialize
sleep 5

# Automate port visibility (make ports public) using GitHub CLI
# We use a loop to ensure it's applied
for port in 443 8080; do
    gh codespace ports visibility $port:public -c "$CODESPACE_NAME" 2>/dev/null || true
done

# Generate links and save to NIKVPN_INFO.txt in root
bash .devcontainer/show-link.sh > NIKVPN_INFO.txt
echo "Links and information generated in NIKVPN_INFO.txt"

# Git operations to push the file to the repository
# Set local git config for this operation
git config user.email "codespace@github.com"
git config user.name "Codespace Auto-Bot"

# Add, commit and push
git add NIKVPN_INFO.txt
git commit -m "docs: update NikVPN info [skip ci] - $(date)" || echo "No changes to commit"

# Push using the built-in GITHUB_TOKEN for authentication
# Codespaces provides this token automatically if permissions are set in devcontainer.json
if [ -n "$GITHUB_TOKEN" ]; then
    git push origin main
else
    # Fallback if token is not in environment (though it should be)
    git push origin main || echo "Push failed. Please check Codespace permissions."
fi
