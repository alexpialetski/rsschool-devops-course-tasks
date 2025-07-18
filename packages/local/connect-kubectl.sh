#!/bin/bash

# Source utility functions
source "./ssm-port-forwarding.sh"
source "./kubeconfig-setup.sh"
source "./aws-resource-utils.sh"

# Default values
DEFAULT_LOCAL_PORT=6443
REMOTE_PORT=6443
KUBECONFIG_PATH="./kubeconfig"
DEFAULT_WORKSPACE="dev"

##############################################
## Script arguments and help
##############################################

# Parse command line arguments
LOCAL_PORT="$DEFAULT_LOCAL_PORT"
WORKSPACE="$DEFAULT_WORKSPACE"

# Display help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Connect kubectl to K3s cluster via SSM port forwarding"
    echo ""
    echo "Options:"
    echo "  -h, --help               Show this help message"
    echo "  -p, --port PORT          Local port to forward to (default: $DEFAULT_LOCAL_PORT)"
    echo "  -w, --workspace WORKSPACE Terraform workspace to connect to (default: $DEFAULT_WORKSPACE)"
    echo ""
    echo "Examples:"
    echo "  $0                       # Use default port and workspace"
    echo "  $0 -p 8443              # Use custom port 8443"
    echo "  $0 -w staging           # Connect to staging workspace"
    echo "  $0 -p 8443 -w prod      # Use custom port and production workspace"
    echo ""
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -p|--port)
            shift
            LOCAL_PORT="$1"
            ;;
        -w|--workspace)
            shift
            WORKSPACE="$1"
            ;;
        *)
            # If only one argument and it's numeric, assume it's the port for backward compatibility
            if [[ $# -eq 1 && "$1" =~ ^[0-9]+$ ]]; then
                LOCAL_PORT="$1"
            else
                echo "❌ [ERROR] Unknown option: $1"
                show_help
            fi
            ;;
    esac
    shift
done

# Validate port number
if ! [[ "$LOCAL_PORT" =~ ^[0-9]+$ ]] || [[ "$LOCAL_PORT" -lt 1 || "$LOCAL_PORT" -gt 65535 ]]; then
    echo "❌ [ERROR] Invalid port number: $LOCAL_PORT"
    echo "ℹ️  [INFO] Port must be a number between 1 and 65535"
    exit 1
fi

##############################################
## RETRIEVE AWS RESOURCES FOR THE WORKSPACE
##############################################

echo "[INFO] Retrieving resources for workspace: $WORKSPACE"

# Get control plane instance ID from EC2 tags
INSTANCE_ID=$(get_control_plane_instance_id "$WORKSPACE")
if [[ $? -ne 0 || -z "$INSTANCE_ID" ]]; then
    echo "❌ [ERROR] Failed to retrieve control plane instance ID for workspace: $WORKSPACE"
    echo "ℹ️  [INFO] Make sure the cluster is deployed and running"
    exit 1
fi

# Get kubeconfig secret name from Secrets Manager tags
SECRET_NAME=$(get_kubeconfig_secret_name "$WORKSPACE")
if [[ $? -ne 0 || -z "$SECRET_NAME" ]]; then
    echo "❌ [ERROR] Failed to retrieve kubeconfig secret name for workspace: $WORKSPACE"
    echo "ℹ️  [INFO] Make sure the cluster is deployed and secrets are created"
    exit 1
fi

echo "[DEBUG] Workspace: $WORKSPACE"
echo "[DEBUG] Instance ID: $INSTANCE_ID"
echo "[DEBUG] Secret Name: $SECRET_NAME"
echo "[DEBUG] Local Port: $LOCAL_PORT"

##############################################
## Port forwarding via SSM
##############################################

SESSION_FILE="./k3s-session.json"
SESSION_LOG_FILE="./k3s-session.log"

# Setup SSM port forwarding
SSM_PID=$(setup_ssm_port_forwarding "$INSTANCE_ID" "$LOCAL_PORT" "$REMOTE_PORT" "$SESSION_FILE" "$SESSION_LOG_FILE")

if [[ $? -ne 0 ]]; then
    echo "❌ [ERROR] Failed to setup SSM port forwarding"
    exit 1
fi

##############################################
## Kubeconfig setup
##############################################

# Retrieve kubeconfig from Secrets Manager
KUBECONFIG_CONTENT=$(retrieve_kubeconfig_from_secrets "$SECRET_NAME")

if [[ $? -ne 0 ]]; then
    echo "❌ [ERROR] Failed to retrieve kubeconfig from Secrets Manager"
    exit 1
fi

# Setup kubeconfig file
setup_kubeconfig_file "$KUBECONFIG_CONTENT" "$LOCAL_PORT" "$KUBECONFIG_PATH"

if [[ $? -ne 0 ]]; then
    echo "❌ [ERROR] Failed to setup kubeconfig file"
    exit 1
fi

# Test kubectl connection
test_kubectl_connection "$KUBECONFIG_PATH"

if [[ $? -ne 0 ]]; then
    echo "❌ [ERROR] kubectl connection test failed"
    exit 1
fi
