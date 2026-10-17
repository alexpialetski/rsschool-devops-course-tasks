# api-server Helm chart

Deploys the Express app from `packages/api-server` (port 3000, health at `/api/health`, CPU load at `/api/load-test`).

## Usage

```sh
helm lint . --strict
helm template api-server . --namespace api-server
helm install api-server . --namespace api-server --create-namespace
helm test api-server -n api-server
```

Via Nx: `npx nx run api-server-chart:lint` / `helm-template`.

CI sets the image tag with `yq -i '.image.tag = "<sha>"' values.yaml`.

## Values

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `2` | Replicas (ignored when autoscaling is enabled) |
| `image.repository` | `ghcr.io/alexpialetski/rsschool-devops-course-tasks/api-server` | Image repository |
| `image.tag` | `latest` | Image tag |
| `image.pullPolicy` | `IfNotPresent` | Pull policy |
| `imagePullSecrets` | `[]` | Pull secrets |
| `env` / `extraEnv` | `PORT`, `NODE_ENV` / `[]` | Container env vars; set `OTEL_EXPORTER_OTLP_ENDPOINT` in `extraEnv` to enable telemetry |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `service.type` / `service.port` | `ClusterIP` / `80` | Service (targets port 3000) |
| `ingress.enabled` | `true` | Create an Ingress |
| `ingress.className` | `traefik` | Ingress class |
| `ingress.host` | `""` | Host (empty matches all) |
| `ingress.path` / `ingress.pathType` | `/` / `Prefix` | Path rule |
| `resources` | 100m/128Mi req, 500m/256Mi limit | Needed for CPU-based HPA |
| `autoscaling.enabled` | `true` | Create HPA (autoscaling/v2) |
| `autoscaling.minReplicas` / `maxReplicas` | `2` / `5` | HPA bounds |
| `autoscaling.targetCPUUtilizationPercentage` | `60` | HPA CPU target |
| `podDisruptionBudget.enabled` / `minAvailable` | `true` / `1` | PDB |
| `podSecurityContext`, `securityContext` | non-root 1001, read-only rootfs, drop ALL | Security contexts |
| `probes.*` | /api/health | Startup, liveness, readiness tuning |
| `nodeSelector`, `tolerations`, `affinity` | empty | Scheduling |
