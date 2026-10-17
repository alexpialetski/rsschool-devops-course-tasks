#!/usr/bin/env bash
# Create a local k3d cluster (idempotent).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [-h]

Creates k3d cluster '$CLUSTER_NAME' (1 server, 1 agent, host port 8080 -> ingress port 80)
and waits for all nodes to be Ready. kubeconfig context: k3d-$CLUSTER_NAME
USAGE
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

require_bin docker "https://docs.docker.com/get-docker/ (and start it)"
require_bin k3d "brew install k3d"
require_bin kubectl "brew install kubectl"

if k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  echo "Cluster '$CLUSTER_NAME' already exists, skipping creation."
  k3d kubeconfig merge "$CLUSTER_NAME" --kubeconfig-switch-context >/dev/null
else
  k3d cluster create "$CLUSTER_NAME" -p "8080:80@loadbalancer" --agents 1 --wait
fi

kubectl config use-context "k3d-$CLUSTER_NAME" >/dev/null
echo "Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl get nodes
