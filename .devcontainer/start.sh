#!/bin/bash

# Kill existing tmux session if it exists
tmux kill-session -t nikvpn 2>/dev/null

# Automate port visibility (make ports public)
# This uses the GitHub CLI 'gh' which is pre-installed in Codespaces
gh codespace ports visibility 443:public 8080:public -c $CODESPACE_NAME 2>/dev/null

# Start a new tmux session
tmux new-session -d -s nikvpn

# Run Xray in the first pane
tmux send-keys -t nikvpn "xray -c .devcontainer/config.json" C-m

# Split the pane and run the Node.js relay
tmux split-window -h -t nikvpn
tmux send-keys -t nikvpn "node .devcontainer/relay.js" C-m

echo "Xray and GAS Relay started in tmux session 'nikvpn'."
echo "Use 'tmux attach -t nikvpn' to see logs."

# Generate links and save to NIKVPN_INFO.txt in root
bash .devcontainer/show-link.sh > NIKVPN_INFO.txt
echo "Links and information saved to NIKVPN_INFO.txt"

# Push the NIKVPN_INFO.txt to the repository so the user can see it without terminal access
git config --global user.email "codespace@github.com"
git config --global user.name "Codespace Auto-Bot"
git add NIKVPN_INFO.txt
git commit -m "docs: update NikVPN info [skip ci]"
git push origin main
