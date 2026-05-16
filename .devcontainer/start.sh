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

# Start watchdog
/tmp/nikvpn_watchdog.sh >> /tmp/nikvpn_watchdog.log 2>&1 &

echo "Services started."

# Background automation
(
    # Wait for everything to settle
    sleep 30

    # 1. Port visibility (Critical for GAS)
    if command -v gh &> /dev/null; then
        gh codespace ports visibility 8443:public 8080:public -c "$CODESPACE_NAME" 2>/dev/null || true
        echo "Ports set to public."
    fi

    # 2. Update Link File
    bash .devcontainer/show-link.sh > NIKVPN_INFO.txt
    echo "NIKVPN_INFO.txt updated locally."

    # 3. Enhanced Git Push with multiple token recovery options
    git config user.email "codespace@github.com"
    git config user.name "Codespace Auto-Bot"

    # Token priorities:
    # 1. MY_GITHUB_TOKEN (User defined secret)
    # 2. gh auth token (GitHub CLI session)
    # 3. GITHUB_TOKEN (Codespace built-in)

    TOKEN="$MY_GITHUB_TOKEN"
    [ -z "$TOKEN" ] && TOKEN=$(gh auth token 2>/dev/null)
    [ -z "$TOKEN" ] && TOKEN="$GITHUB_TOKEN"

    REPO="$GITHUB_REPOSITORY"
    [ -z "$REPO" ] && REPO=$(git remote get-url origin | sed 's/https:\/\/github.com\///;s/\.git$//')

    git add NIKVPN_INFO.txt
    if git commit -m "docs: auto-update links [skip ci] - $(date)" 2>/dev/null; then
        if [ -n "$TOKEN" ] && [ -n "$REPO" ]; then
            REMOTE_URL="https://x-access-token:${TOKEN}@github.com/${REPO}.git"
            # Try pushing up to 3 times
            for i in {1..3}; do
                echo "Push attempt $i..."
                git push "$REMOTE_URL" HEAD && { echo "Push successful!"; break; }
                sleep 10
            done
        else
            echo "Failed to push: No valid token or repository name found."
            echo "TOKEN length: ${#TOKEN}"
            echo "REPO: $REPO"
        fi
    else
        echo "Nothing to commit (file identical)."
    fi
) &> /tmp/nikvpn_startup.log &
