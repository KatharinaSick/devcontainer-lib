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

All scripts that wait for resources to become ready accept a `--timeout` flag:

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
