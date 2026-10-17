#!/usr/bin/env bash
# Delete the local k3d cluster.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $(basename "$0")   Deletes k3d cluster '$CLUSTER_NAME'."
  exit 0
fi

require_bin k3d "brew install k3d"

if k3d cluster list "$CLUSTER_NAME" >/dev/null 2>&1; then
  k3d cluster delete "$CLUSTER_NAME"
else
  echo "Cluster '$CLUSTER_NAME' does not exist, nothing to do."
fi
