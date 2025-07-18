#!/bin/bash

# Default values
DEFAULT_LOCAL_PORT=6443
REMOTE_PORT=6443
KUBECONFIG_PATH="./kubeconfig"

check_port() {
    local port=$1

    nc -z localhost "$port" 2>/dev/null
}

##############################################
## Script arguments and help
##############################################

# Parse command line arguments
LOCAL_PORT="$DEFAULT_LOCAL_PORT"
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: $0 [LOCAL_PORT]"
        echo ""
        echo "Connect kubectl to K3s cluster via SSM port forwarding"
        echo ""
        echo "Arguments:"
        echo "  LOCAL_PORT    Local port to forward to (default: $DEFAULT_LOCAL_PORT)"
        echo ""
        echo "Examples:"
        echo "  $0            # Use default port $DEFAULT_LOCAL_PORT"
        echo "  $0 8443       # Use custom port 8443"
        echo ""
        exit 0
    fi
    LOCAL_PORT="$1"
fi

# Validate port number
if ! [[ "$LOCAL_PORT" =~ ^[0-9]+$ ]] || [[ "$LOCAL_PORT" -lt 1 || "$LOCAL_PORT" -gt 65535 ]]; then
    echo "❌ [ERROR] Invalid port number: $LOCAL_PORT"
    echo "ℹ️  [INFO] Port must be a number between 1 and 65535"
    exit 1
fi

##############################################
## TERRAFORM OUTPUTS FROM CLUSTER PROJECT
##############################################

# Check if terraform outputs file exists and source it
if [[ ! -f "../cluster/terraform-outputs.env" ]]; then
    echo "❌ [ERROR] Terraform outputs file not found: ../cluster/terraform-outputs.env"
    echo "ℹ️  [INFO] Please run: npx nx run cluster:terraform-output"
    exit 1
fi

source "../cluster/terraform-outputs.env"

INSTANCE_ID="$control_plane_instance_ids"
SECRET_NAME="$k3s_kubeconfig_secret_name"
TEMP_VALUE="$temp_kubeconfig_value"

if [[ -z "$TEMP_VALUE" ]]; then
    echo "❌ [ERROR] Could not get temp_kubeconfig_value from terraform output"
    exit 1
fi

if [[ -z "$INSTANCE_ID" ]]; then
    echo "❌ [ERROR] Could not get control plane instance ID from terraform output"
    exit 1
fi

if [[ -z "$SECRET_NAME" ]]; then
    echo "❌ [ERROR] Could not get kubeconfig secret name from terraform output"
    exit 1
fi

echo "[DEBUG] Instance ID: $INSTANCE_ID"
echo "[DEBUG] Secret Name: $SECRET_NAME"
echo "[DEBUG] Local Port: $LOCAL_PORT"
echo "[DEBUG] Initial placeholder value: $TEMP_VALUE"

##############################################
## Port forwarding via SSM
##############################################

echo "🚀 [INFO] === Connecting kubectl to K3s cluster ==="

# Check if port is already in use
if check_port "$LOCAL_PORT"; then
    echo "❌ [ERROR] Port $LOCAL_PORT is already in use."
    echo "ℹ️  [INFO] Please disconnect first: npx nx run local:disconnect-kubectl"
    echo "ℹ️  [INFO] Or use a different port: npx nx run local:connect-kubectl -- [PORT]"
    exit 1
fi

# Start SSM port forwarding
echo "🔄 [INFO] Starting SSM port forwarding..."
echo "[DEBUG] Remote Port: $REMOTE_PORT"

SESSION_FILE="./k3s-session.json"
SESSION_LOG_FILE="./k3s-session.log"
TIMEOUT=60

# Start SSM session in background
aws ssm start-session \
    --target="$INSTANCE_ID" \
    --document-name="AWS-StartPortForwardingSession" \
    --parameters="{\"portNumber\":[\"$REMOTE_PORT\"], \"localPortNumber\":[\"$LOCAL_PORT\"]}" \
    > "$SESSION_LOG_FILE" 2>&1 &

SSM_PID=$!
echo "[DEBUG] SSM session started with PID: $SSM_PID"

# Wait for port forwarding to establish
echo "⏳ [INFO] Waiting for port forwarding to establish..."
COUNTER=0
while [[ $COUNTER -lt $TIMEOUT ]]; do
    echo "[DEBUG] Checking port $LOCAL_PORT (attempt $((COUNTER + 1))/$TIMEOUT)..."

    # Check if SSM process is still running
    if ! kill -0 $SSM_PID 2>/dev/null; then
        echo "❌ [ERROR] SSM session process died unexpectedly"
        echo "Check log file: $SESSION_LOG_FILE"
        exit 1
    fi

    if check_port "$LOCAL_PORT"; then
        echo "✅ [INFO] Port forwarding established successfully"
        break
    fi

    # Show progress every 10 seconds
    if [[ $((COUNTER % 10)) -eq 0 && $COUNTER -gt 0 ]]; then
        echo "[DEBUG] Still waiting... (${COUNTER}s elapsed)"
    fi

    sleep 1
    ((COUNTER++))
done

if [[ $COUNTER -eq $TIMEOUT ]]; then
    echo "❌ [ERROR] Port forwarding failed to establish within ${TIMEOUT}s"
    echo "Check log file: $SESSION_LOG_FILE"
    echo "Last few lines of log:"
    tail -10 "$SESSION_LOG_FILE" 2>/dev/null || echo "Could not read log file"
    kill $SSM_PID 2>/dev/null || true
    exit 1
fi

# Store session information
cat > "$SESSION_FILE" << EOF
{
    "instance_id": "$INSTANCE_ID",
    "remote_port": $REMOTE_PORT,
    "local_port": $LOCAL_PORT,
    "pid": $SSM_PID,
    "log_file": "$SESSION_LOG_FILE",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "[DEBUG] Session information saved to: $SESSION_FILE"


##############################################
## Kubeconfig setup
##############################################

echo "⚙️  [INFO] Setting up kubeconfig..."

KUBECONFIG_TIMEOUT=300  # 5 minutes timeout
SLEEP_INTERVAL=5        # 5 seconds between checks

echo "⏳ [INFO] Waiting for kubeconfig to be uploaded to Secrets Manager..."
echo "[DEBUG] Secret name: $SECRET_NAME"
echo "[DEBUG] Timeout: ${KUBECONFIG_TIMEOUT}s, Check interval: ${SLEEP_INTERVAL}s"

KUBECONFIG_COUNTER=0
KUBECONFIG_CONTENT=""

while [[ $KUBECONFIG_COUNTER -lt $KUBECONFIG_TIMEOUT ]]; do
    # Try to retrieve the actual kubeconfig
    KUBECONFIG_CONTENT=$(aws secretsmanager get-secret-value \
        --secret-id "$SECRET_NAME" \
        --query 'SecretString' \
        --output text 2>/dev/null || echo "")

    # Check if the content is different from the placeholder and not empty
    if [[ -n "$KUBECONFIG_CONTENT" && "$KUBECONFIG_CONTENT" != "$TEMP_VALUE" ]]; then
        echo "✅ [INFO] Kubeconfig is ready and differs from placeholder"
        echo "✅ [INFO] Successfully retrieved kubeconfig from Secrets Manager"
        break
    fi

    if [[ $((KUBECONFIG_COUNTER % (SLEEP_INTERVAL * 4))) -eq 0 ]]; then
        echo "[DEBUG] Still waiting for kubeconfig to be uploaded... (${KUBECONFIG_COUNTER}s/${KUBECONFIG_TIMEOUT}s)"
    fi

    sleep "$SLEEP_INTERVAL"
    ((KUBECONFIG_COUNTER += SLEEP_INTERVAL))
done

if [[ $KUBECONFIG_COUNTER -ge $KUBECONFIG_TIMEOUT ]]; then
    echo "❌ [ERROR] Failed to retrieve kubeconfig from Secrets Manager within ${KUBECONFIG_TIMEOUT}s"
    echo "ℹ️  [INFO] The EC2 instance may still be starting up or configuring K3s"
    exit 1
fi

if [[ -z "$KUBECONFIG_CONTENT" ]]; then
    echo "❌ [ERROR] Failed to retrieve kubeconfig from Secrets Manager"
    exit 1
fi

# Modify kubeconfig to use localhost and the forwarded port
MODIFIED_KUBECONFIG=$(echo "$KUBECONFIG_CONTENT" | sed "s/127.0.0.1:6443/localhost:$LOCAL_PORT/g")

# Save kubeconfig
echo "$MODIFIED_KUBECONFIG" > "$KUBECONFIG_PATH"
echo "[DEBUG] Kubeconfig saved to: $KUBECONFIG_PATH"

##############################################
## Test kubectl connection
##############################################

echo "🔍 [INFO] Testing kubectl connection..."

if kubectl --kubeconfig="$KUBECONFIG_PATH" cluster-info &>/dev/null; then
    echo "✅ [INFO] kubectl connection successful!"
else
    echo "❌ [ERROR] kubectl connection failed"
    exit 1
fi
