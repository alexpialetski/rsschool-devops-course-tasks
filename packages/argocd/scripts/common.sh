# Shared helpers, sourced by the other scripts.

CLUSTER_NAME="rsschool"
ARGOCD_CHART_VERSION="10.10.5"
ARGOCD_NAMESPACE="argocd"

require_bin() {
  # usage: require_bin <binary> <install hint>
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: '$1' is required but not installed. Install hint: $2" >&2
    exit 1
  fi
}
