#!/bin/bash

# Navigate to the root directory of the repository
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Kill existing tmux session if it exists
tmux kill-session -t nikvpn 2>/dev/null

# Start a new tmux session
tmux new-session -d -s nikvpn

# Create the watchdog script
cat << 'EOF' > /tmp/nikvpn_watchdog.sh
#!/bin/bash
while true; do
    # Check Xray
    if ! pgrep -x "xray" > /dev/null; then
        echo "$(date): Restarting Xray..."
        tmux send-keys -t nikvpn:0.0 "xray -c .devcontainer/config.json" C-m
    fi

    # Check Node Relay
    if ! pgrep -f "node .devcontainer/relay.js" > /dev/null; then
        echo "$(date): Restarting Node Relay..."
        # Find if it's in a different pane or needs a new one
        tmux send-keys -t nikvpn:0.1 "node .devcontainer/relay.js" C-m
    fi
    sleep 30
done
EOF
chmod +x /tmp/nikvpn_watchdog.sh

# Setup panes in tmux
tmux send-keys -t nikvpn "xray -c .devcontainer/config.json" C-m
tmux split-window -h -t nikvpn
tmux send-keys -t nikvpn "node .devcontainer/relay.js" C-m

# Start watchdog in a separate background process
/tmp/nikvpn_watchdog.sh >> /tmp/nikvpn_watchdog.log 2>&1 &

echo "Services started in tmux session 'nikvpn' with watchdog."

# Background tasks for port visibility and link update
(
    # Wait for services to initialize
    sleep 15

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

    # 3. Git Push Logic (Bulletproof)
    git config user.email "codespace@github.com"
    git config user.name "Codespace Auto-Bot"

    git add NIKVPN_INFO.txt
    if git commit -m "docs: auto-update links [skip ci] - $(date)" 2>/dev/null; then
        if [ -n "$GITHUB_TOKEN" ]; then
            # Construct authenticated remote URL
            REMOTE_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
            git push "$REMOTE_URL" HEAD || echo "Push failed with token."
        else
            git push origin HEAD || echo "Push failed (no token)."
        fi
    else
        echo "Nothing to commit."
    fi
) &> /tmp/nikvpn_startup.log &

echo "Background tasks running. Check /tmp/nikvpn_startup.log"
