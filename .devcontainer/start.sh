#!/bin/bash

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
echo "Use 'tmux attach -t nikvpn' to see logs."
bash .devcontainer/show-link.sh
