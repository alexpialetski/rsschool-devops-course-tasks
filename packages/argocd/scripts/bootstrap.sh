#!/usr/bin/env bash
# Install Argo CD via Helm and register the api-server Application.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

TIMEOUT_SECONDS=300

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--kubeconfig PATH]

Installs Argo CD (argo/argo-cd $ARGOCD_CHART_VERSION) into namespace '$ARGOCD_NAMESPACE',
applies packages/argocd/apps/*.yaml and waits for the Applications to be Synced/Healthy.

Options:
  --kubeconfig PATH   Use this kubeconfig (e.g. packages/local/kubeconfig for AWS).
                      Default: current kube context.
  -h, --help          Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kubeconfig)
      [[ $# -ge 2 ]] || { echo "ERROR: --kubeconfig needs a value" >&2; exit 1; }
      # Resolve relative to the caller's directory before anything changes cwd.
      KUBECONFIG="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
      [[ -f "$KUBECONFIG" ]] || { echo "ERROR: kubeconfig not found: $KUBECONFIG" >&2; exit 1; }
      export KUBECONFIG
      shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

require_bin helm "brew install helm"
require_bin kubectl "brew install kubectl"

echo "==> Using context: $(kubectl config current-context)"

echo "==> Installing Argo CD $ARGOCD_CHART_VERSION"
helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd \
  --version "$ARGOCD_CHART_VERSION" \
  --namespace "$ARGOCD_NAMESPACE" --create-namespace \
  -f "$ROOT_DIR/values.yaml" \
  --wait --timeout 5m

echo "==> Applying Applications"
kubectl apply -n "$ARGOCD_NAMESPACE" -f "$ROOT_DIR/apps/"

echo "==> Waiting for Applications to be Synced/Healthy (timeout ${TIMEOUT_SECONDS}s)"
deadline=$((SECONDS + TIMEOUT_SECONDS))
while true; do
  all_ok=true
  for app in $(kubectl get applications.argoproj.io -n "$ARGOCD_NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
    sync="$(kubectl get applications.argoproj.io "$app" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.sync.status}')"
    health="$(kubectl get applications.argoproj.io "$app" -n "$ARGOCD_NAMESPACE" -o jsonpath='{.status.health.status}')"
    echo "    $app: sync=${sync:-?} health=${health:-?}"
    [[ "$sync" == "Synced" && "$health" == "Healthy" ]] || all_ok=false
  done
  if $all_ok; then
    echo "==> All Applications are Synced and Healthy"
    break
  fi
  if (( SECONDS >= deadline )); then
    echo "ERROR: timed out waiting for Applications" >&2
    kubectl get applications.argoproj.io -n "$ARGOCD_NAMESPACE" >&2 || true
    exit 1
  fi
  sleep 10
done
kubectl get applications.argoproj.io -n "$ARGOCD_NAMESPACE"
