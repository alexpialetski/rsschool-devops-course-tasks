#!/bin/bash
# Disconnect kubectl from K3s cluster by stopping SSM port forwarding

set -e

# Default values
SESSION_FILE="./k3s-session.json"
KUBECONFIG_PATH="./kubeconfig"

echo "🔌 [INFO] === Disconnecting kubectl from K3s cluster ==="

# Check if session file exists
if [[ ! -f "$SESSION_FILE" ]]; then
    echo "ℹ️  [INFO] No active session found (no session file: $SESSION_FILE)"
    echo "ℹ️  [INFO] Nothing to disconnect"
    exit 0
fi

echo "[DEBUG] Reading session information from: $SESSION_FILE"

# Parse session file
INSTANCE_ID=$(cat "$SESSION_FILE" | grep '"instance_id"' | cut -d'"' -f4)
LOCAL_PORT=$(cat "$SESSION_FILE" | grep '"local_port"' | cut -d':' -f2 | tr -d ' ,')
SSM_PID=$(cat "$SESSION_FILE" | grep '"pid"' | cut -d':' -f2 | tr -d ' ,')
LOG_FILE=$(cat "$SESSION_FILE" | grep '"log_file"' | cut -d'"' -f4)

echo "[DEBUG] Instance ID: $INSTANCE_ID"
echo "[DEBUG] Local Port: $LOCAL_PORT"
echo "[DEBUG] Process ID: $SSM_PID"
echo "[DEBUG] Log File: $LOG_FILE"

# Try to get active SSM sessions and terminate them
echo "🔄 [INFO] Terminating active SSM sessions..."
if [[ -n "$INSTANCE_ID" ]]; then
    # Get active sessions for this instance
    SESSION_IDS=$(aws ssm describe-sessions \
        --state "Active" \
        --query "Sessions[?Target=='$INSTANCE_ID'].SessionId" \
        --output text 2>/dev/null || echo "")

    if [[ -n "$SESSION_IDS" ]]; then
        for SESSION_ID in $SESSION_IDS; do
            echo "[DEBUG] Terminating session: $SESSION_ID"
            aws ssm terminate-session --session-id "$SESSION_ID" &>/dev/null || true
        done
    fi
fi

# Try to kill the local process
if [[ -n "$SSM_PID" ]]; then
    echo "🔄 [INFO] Killing local process: $SSM_PID"
    kill "$SSM_PID" 2>/dev/null || true
fi

# Clean up session file
echo "🧹 [INFO] Cleaning up session file: $SESSION_FILE"
rm -f "$SESSION_FILE"

# Clean up kubeconfig if it exists
if [[ -f "$KUBECONFIG_PATH" ]]; then
    echo "🧹 [INFO] Cleaning up kubeconfig file: $KUBECONFIG_PATH"
    rm -f "$KUBECONFIG_PATH"
fi

# Clean up log file if it exists
if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    echo "🧹 [INFO] Cleaning up log file: $LOG_FILE"
    rm -f "$LOG_FILE"
fi

echo "✅ [INFO] Disconnection completed"
echo "ℹ️  [INFO] kubectl access to K3s cluster has been terminated"
