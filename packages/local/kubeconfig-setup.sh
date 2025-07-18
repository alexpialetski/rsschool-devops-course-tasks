#!/bin/bash
# Kubeconfig retrieval and setup utilities

retrieve_kubeconfig_from_secrets() {
    local secret_name="$1"
    local kubeconfig_timeout="${2:-300}"  # 5 minutes timeout
    local sleep_interval="${3:-5}"        # 5 seconds between checks

    echo "⚙️ [INFO] Setting up kubeconfig..." >&2
    echo "⏳ [INFO] Waiting for kubeconfig to be uploaded to Secrets Manager..." >&2
    echo "[DEBUG] Secret name: $secret_name" >&2
    echo "[DEBUG] Timeout: ${kubeconfig_timeout}s, Check interval: ${sleep_interval}s" >&2

    local kubeconfig_counter=0
    local kubeconfig_content=""

    while [[ $kubeconfig_counter -lt $kubeconfig_timeout ]]; do
        # Try to retrieve the actual kubeconfig
        kubeconfig_content=$(aws secretsmanager get-secret-value \
            --secret-id "$secret_name" \
            --query 'SecretString' \
            --output text 2>/dev/null || echo "")

        # Check if content is not empty and appears to be valid kubeconfig (has 'apiVersion' field)
        if [[ -n "$kubeconfig_content" && "$kubeconfig_content" == *"apiVersion"* ]]; then
            echo "✅ [INFO] Kubeconfig is ready and differs from placeholder" >&2
            echo "✅ [INFO] Successfully retrieved kubeconfig from Secrets Manager" >&2
            break
        fi

        if [[ $((kubeconfig_counter % (sleep_interval * 4))) -eq 0 ]]; then
            echo "[DEBUG] Still waiting for kubeconfig to be uploaded... (${kubeconfig_counter}s/${kubeconfig_timeout}s)" >&2
        fi

        sleep "$sleep_interval"
        ((kubeconfig_counter += sleep_interval))
    done

    if [[ $kubeconfig_counter -ge $kubeconfig_timeout ]]; then
        echo "❌ [ERROR] Failed to retrieve kubeconfig from Secrets Manager within ${kubeconfig_timeout}s" >&2
        echo "ℹ️  [INFO] The EC2 instance may still be starting up or configuring K3s" >&2
        return 1
    fi

    if [[ -z "$kubeconfig_content" ]]; then
        echo "❌ [ERROR] Failed to retrieve kubeconfig from Secrets Manager" >&2
        return 1
    fi

    # Return the kubeconfig content
    echo "$kubeconfig_content"
    return 0
}

setup_kubeconfig_file() {
    local kubeconfig_content="$1"
    local local_port="$2"
    local kubeconfig_path="$3"

    echo "💾 [INFO] Saving kubeconfig file..." >&2

    # Modify kubeconfig to use localhost and the forwarded port
    local modified_kubeconfig=$(echo "$kubeconfig_content" | sed "s/127.0.0.1:6443/localhost:$local_port/g")

    # Save kubeconfig
    echo "$modified_kubeconfig" > "$kubeconfig_path"
    echo "[DEBUG] Kubeconfig saved to: $kubeconfig_path" >&2

    return 0
}

test_kubectl_connection() {
    local kubeconfig_path="$1"

    echo "🔍 [INFO] Testing kubectl connection..." >&2

    if kubectl --kubeconfig="$kubeconfig_path" cluster-info &>/dev/null; then
        echo "✅ [INFO] kubectl connection successful!" >&2
        return 0
    else
        echo "❌ [ERROR] kubectl connection failed" >&2
        return 1
    fi
}
