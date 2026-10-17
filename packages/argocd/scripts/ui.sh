#!/usr/bin/env bash
# Print the Argo CD admin password and port-forward the UI to localhost:8081.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $(basename "$0")   Uses the current kube context (set KUBECONFIG for AWS)."
  exit 0
fi

require_bin kubectl "brew install kubectl"

password="$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)"
echo "Argo CD UI:  http://localhost:8081"
echo "Username:    admin"
echo "Password:    $password"
echo "(Ctrl+C to stop port-forwarding)"
kubectl -n "$ARGOCD_NAMESPACE" port-forward svc/argocd-server 8081:80
