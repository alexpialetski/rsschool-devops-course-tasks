# argocd

GitOps CD for the `api-server` chart. Argo CD is installed with Helm and an Argo CD
`Application` watches `packages/api-server-chart` on `main`, auto-syncing with prune and self-heal.

## Flow

1. CI builds the image and pushes it to GHCR.
2. CI commits the new image tag into `packages/api-server-chart/values.yaml` on `main`.
3. Argo CD detects the commit (polls every ~3 min), renders the chart and syncs it to the
   `api-server` namespace.

## Layout

- `values.yaml` - values for `argo/argo-cd` (chart version pinned in `scripts/common.sh`, currently 10.10.5).
- `apps/api-server.yaml` - the Application (applied by `bootstrap.sh`).
- `scripts/` - `cluster-up.sh`, `cluster-down.sh`, `bootstrap.sh`, `ui.sh`.

## Local quick start (k3d)

Requires docker, `k3d`, `kubectl`, `helm` (`brew install k3d kubectl helm`).

```bash
npx nx run argocd:cluster-up     # k3d cluster "rsschool", host port 8080 -> ingress
npx nx run argocd:bootstrap      # install Argo CD, apply apps, wait for Synced/Healthy
# app:      http://localhost:8080
npx nx run argocd:ui             # Argo CD UI: http://localhost:8081 (prints admin password)
npx nx run argocd:cluster-down   # cleanup
```

## AWS

```bash
npx nx run local:connect-kubectl
npx nx run argocd:bootstrap -- --kubeconfig packages/local/kubeconfig
```

The `Deploy K8s Applications` workflow does the same from CI (manual `workflow_dispatch`).

## Notes

- The GHCR package must be public, otherwise add an `imagePullSecret` to the chart.
- Argo CD pulls from the public GitHub repo, so no repository credentials are needed.
- `npx nx run argocd:lint` runs `bash -n` on scripts and parses the YAML with node (js-yaml).
