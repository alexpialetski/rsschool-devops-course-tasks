#!/bin/bash
# AWS Resource Retrieval Utilities

# Get Control Plane Instance ID by Workspace and NodeType tag
get_control_plane_instance_id() {
    local workspace="${1:-dev}"
    local node_type="control-plane"

    echo "[DEBUG] Retrieving control plane instance ID for workspace: $workspace" >&2

    local instance_id=$(aws ec2 describe-instances \
        --filters "Name=tag:Workspace,Values=$workspace" "Name=tag:NodeType,Values=$node_type" "Name=instance-state-name,Values=running" \
        --query "Reservations[0].Instances[0].InstanceId" \
        --output text)

    if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
        echo "❌ [ERROR] No control plane instance found for workspace: $workspace" >&2
        return 1
    fi

    echo "[DEBUG] Found control plane instance ID: $instance_id" >&2
    echo "$instance_id"
    return 0
}

# Get Kubeconfig Secret Name by Workspace and SecretType tag
get_kubeconfig_secret_name() {
    local workspace="${1:-dev}"
    local secret_type="kubeconfig"

    echo "[DEBUG] Retrieving kubeconfig secret name for workspace: $workspace" >&2

    local secret_name=$(aws secretsmanager list-secrets \
        --filters Key=tag-key,Values=Workspace Key=tag-value,Values=$workspace Key=tag-key,Values=SecretType Key=tag-value,Values=$secret_type \
        --query "SecretList[0].Name" \
        --output text)

    if [[ -z "$secret_name" || "$secret_name" == "None" ]]; then
        echo "❌ [ERROR] No kubeconfig secret found for workspace: $workspace" >&2
        return 1
    fi

    echo "[DEBUG] Found kubeconfig secret name: $secret_name" >&2
    echo "$secret_name"
    return 0
}
