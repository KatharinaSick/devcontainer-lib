# devcontainer-lib

Reusable init scripts for devcontainer environments.

## Usage

In your `post-create.sh`, download the library at a pinned version, run the scripts you need,
then delete the temp directory to keep the working state clean:

```bash
# If your post-create.sh is at .devcontainer/post-create.sh:
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# If your post-create.sh is at .devcontainer/<name>/post-create.sh:
# REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

LIB_VERSION="v1.0.0"

LIB_DIR=$(mktemp -d)
curl -fsSL "https://github.com/KatharinaSick/devcontainer-lib/archive/refs/tags/${LIB_VERSION}.tar.gz" \
  | tar -xz --strip-components=2 -C "$LIB_DIR"

"$LIB_DIR/gum/init.sh" --version v0.17.0

"$LIB_DIR/kubernetes/init.sh" \
  --kind-version v0.31.0 \
  --kubectl-version v1.35.0 \
  --kubens-version v0.11.0 \
  --k9s-version v0.50.18 \
  --helm-version v4.1.4

"$LIB_DIR/argocd/init.sh" --version v2.14.0

rm -rf "$LIB_DIR"
```

## Available Scripts

Each tool has its own subdirectory with an `init.sh` script.

## Ports

| Port        | Service                        |
|-------------|--------------------------------|
| 30100       | ArgoCD                         |
| 30101       | Argo Rollouts                  |
| 30102       | Prometheus                     |
| 30103       | Jaeger                         |
| 30104       | GCP API Mock                   |
| 30105       | Ollama                         |
| 30106       | OpenTelemetry Collector (gRPC) |
| 30107       | OpenTelemetry Collector (HTTP) |
| 30108       | Qdrant (HTTP)                  |
| 30109       | Qdrant (gRPC)                  |
| 30110       | Gitea                          |
| 30111       | Argo Workflows                 |
| 30200–30204 | Custom app (reserved)          |

## Versioning

Releases follow [Conventional Commits](https://www.conventionalcommits.org/). Pin to a release
tag in your `post-create.sh` to ensure your environment stays reproducible when this library
is updated.

## Common Options

All scripts that deploy Kubernetes resources accept `--no-wait` and `--timeout`.

### `--no-wait` and `wait.sh`

By default each script blocks until its workload is ready. Pass `--no-wait` to return
immediately after submitting the manifests, then use `wait.sh` at the end to wait for
everything at once — useful when installing multiple tools in parallel:

```bash
"$LIB_DIR/argo-workflows/init.sh" --version v0.45.0 --no-wait
"$LIB_DIR/gitea/init.sh"          --version v10.6.0  --no-wait
"$LIB_DIR/prometheus/init.sh"     --version v27.5.1  --no-wait
# ... other installs ...

"$LIB_DIR/wait.sh" argo-workflows gitea prometheus
```

`wait.sh` accepts an optional `--timeout` (default `5m`) and any number of tool names.
Available tools: `argo-events`, `argo-rollouts`, `argo-workflows`, `gitea`, `jaeger`,
`kube-state-metrics`, `kyverno`, `ollama`, `otel-collector`, `prometheus`,
`prometheus-operator`, `qdrant`.

> **Note:** `argo-events` is special — when `--no-wait` is used, the default EventBus
> manifest is also deferred and applied by `wait.sh` once the controller is ready.

### `--timeout`

All scripts that wait for resources accept a `--timeout` flag:

```bash
"$LIB_DIR/argocd/init.sh" --version v2.14.0 --timeout 10m
```

The default varies per script (most use `5m`, Ollama uses `10m`, OTel Collector uses `2m`).
Pass any [Go duration string](https://pkg.go.dev/time#ParseDuration) (e.g. `30s`, `5m`, `1h`).

## Adding a New Script

Each tool lives in its own directory and follows the same interface:

```bash
lib/<tool>/init.sh --version <version>
```

Scripts are idempotent and print progress to stdout.
