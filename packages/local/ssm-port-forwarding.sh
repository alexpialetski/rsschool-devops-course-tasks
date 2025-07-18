#!/bin/bash
# SSM Port Forwarding utilities

check_port() {
    local port=$1
    nc -z localhost "$port" 2>/dev/null
}

setup_ssm_port_forwarding() {
    local instance_id="$1"

    local local_port="$2"
    local remote_port="$3"

    local session_file="$4"
    local session_log_file="$5"

    local timeout="60"

    echo "🚀 [INFO] === Connecting kubectl to K3s cluster ===" >&2

    # Check if port is already in use
    if check_port "$local_port"; then
        echo "❌ [ERROR] Port $local_port is already in use." >&2
        echo "ℹ️  [INFO] Please disconnect first: npx nx run local:disconnect-kubectl" >&2
        echo "ℹ️  [INFO] Or use a different port: npx nx run local:connect-kubectl -- [PORT]" >&2
        return 1
    fi

    # Start SSM port forwarding
    echo "🔄 [INFO] Starting SSM port forwarding..." >&2
    echo "[DEBUG] Remote Port: $remote_port" >&2

    # Start SSM session in background
    aws ssm start-session \
        --target="$instance_id" \
        --document-name="AWS-StartPortForwardingSession" \
        --parameters="{\"portNumber\":[\"$remote_port\"], \"localPortNumber\":[\"$local_port\"]}" \
        > "$session_log_file" 2>&1 &

    local ssm_pid=$!
    echo "[DEBUG] SSM session started with PID: $ssm_pid" >&2

    # Wait for port forwarding to establish
    echo "⏳ [INFO] Waiting for port forwarding to establish..." >&2
    local counter=0
    while [[ $counter -lt $timeout ]]; do
        echo "[DEBUG] Checking port $local_port (attempt $((counter + 1))/$timeout)..." >&2

        # Check if SSM process is still running
        if ! kill -0 $ssm_pid 2>/dev/null; then
            echo "❌ [ERROR] SSM session process died unexpectedly" >&2
            echo "Check log file: $session_log_file" >&2
            return 1
        fi

        if check_port "$local_port"; then
            echo "✅ [INFO] Port forwarding established successfully" >&2
            break
        fi

        # Show progress every 10 seconds
        if [[ $((counter % 10)) -eq 0 && $counter -gt 0 ]]; then
            echo "[DEBUG] Still waiting... (${counter}s elapsed)" >&2
        fi

        sleep 1
        ((counter++))
    done

    if [[ $counter -eq $timeout ]]; then
        echo "❌ [ERROR] Port forwarding failed to establish within ${timeout}s" >&2
        echo "Check log file: $session_log_file" >&2
        echo "Last few lines of log:" >&2
        tail -10 "$session_log_file" 2>/dev/null || echo "Could not read log file" >&2
        kill $ssm_pid 2>/dev/null || true
        return 1
    fi

    # Store session information
    cat > "$session_file" << EOF
{
    "instance_id": "$instance_id",
    "remote_port": $remote_port,
    "local_port": $local_port,
    "pid": $ssm_pid,
    "log_file": "$session_log_file",
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    echo "[DEBUG] Session information saved to: $session_file" >&2

    # Return the PID for reference
    echo "$ssm_pid"
    return 0
}
