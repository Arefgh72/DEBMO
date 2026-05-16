#!/bin/bash

# Navigate to the root directory of the repository
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Kill existing tmux session if it exists to avoid conflicts
tmux kill-session -t nikvpn 2>/dev/null

# Start a new tmux session in the background
tmux new-session -d -s nikvpn

# Run Xray in the first pane
tmux send-keys -t nikvpn "xray -c .devcontainer/config.json" C-m

# Split the pane and run the Node.js relay
tmux split-window -h -t nikvpn
tmux send-keys -t nikvpn "node .devcontainer/relay.js" C-m

echo "Services started in tmux session 'nikvpn'."

# Perform network-dependent tasks in the background to prevent blocking Codespace startup
(
    # Wait for services and network to be ready
    sleep 10

    # 1. Automate port visibility
    if command -v gh &> /dev/null; then
        for port in 443 8080; do
            gh codespace ports visibility $port:public -c "$CODESPACE_NAME" 2>/dev/null || true
        done
        echo "Ports set to public."
    fi

    # 2. Generate Link File
    bash .devcontainer/show-link.sh > NIKVPN_INFO.txt
    echo "NIKVPN_INFO.txt generated."

    # 3. Git Push Logic
    git config user.email "codespace@github.com"
    git config user.name "Codespace Auto-Bot"

    git add NIKVPN_INFO.txt
    if git commit -m "docs: auto-update links [skip ci] - $(date)" 2>/dev/null; then
        # Use GITHUB_TOKEN for authentication if available
        if [ -n "$GITHUB_TOKEN" ]; then
            # Construct authenticated remote URL
            REMOTE_URL=$(git remote get-url origin | sed "s/https:\/\//https:\/\/x-access-token:${GITHUB_TOKEN}@/")
            git push "$REMOTE_URL" main || echo "Push failed with token."
        else
            git push origin main || echo "Push failed (no token)."
        fi
    else
        echo "Nothing to commit."
    fi
) &> /tmp/nikvpn_startup.log &

echo "Background tasks (ports and git push) are running in the background."
echo "Check /tmp/nikvpn_startup.log for progress."
