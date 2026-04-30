# Agent Instructions

## Purpose

This repo is a library of reusable init scripts for devcontainer environments. Consumers download
it as a versioned tarball in their `post-create.sh`, run the scripts they need, then delete the
temp directory. Scripts are never committed into the consuming repo.

## Repository Structure

```
lib/
  arch.sh                    # Shared arch detection (amd64/arm64) — sourced by init scripts that need it
  <tool>/
    init.sh                  # Installs the tool
    values.yaml              # Helm values (Helm-based tools only)
    manifests/               # Raw Kubernetes manifests (only when Helm isn't used)
lib/kubernetes/config.yaml   # Kind cluster config — contains all NodePort mappings
```

## Adding a New Tool

1. Create `lib/<tool>/init.sh` following the conventions below
2. Create `lib/<tool>/values.yaml` if using Helm
3. If the tool exposes a UI via NodePort:
   - Assign the next available port (check the README ports table)
   - Add the port to `lib/kubernetes/config.yaml` under `extraPortMappings`
   - Add the port to the README ports table

## Script Conventions

Every `init.sh` must follow this exact structure:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"  # only if referencing sibling files

help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo " --help             Display this help message"
  echo " --version <ver>    <Tool> version to install (required)"
}

# Parse flags
version=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) help; exit 0 ;;
    --version)
      if [[ -z "${2-}" ]]; then echo "Error: --version requires a value" >&2; exit 1; fi
      version="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$version" ]]; then
  echo "Error: --version is required" >&2
  exit 1
fi

echo "✨ Installing <tool>"
# ... installation steps ...

echo "✅ <Tool> is ready"
```

Key rules:
- **All versions are passed as flags** (`--version`, `--kind-version`, etc.) — never hardcoded inside a script
- **`✨`** for progress steps, **`✅`** for the final success line
- **`SCRIPT_DIR`** for referencing sibling files (`values.yaml`, `manifests/`)
- **Architecture detection**: source `../arch.sh` when downloading arch-specific binaries
- Scripts must be **executable** (`chmod +x`)
- Scripts should be **idempotent** where possible

## Helm Pattern

For Helm-based tools, follow this structure exactly:

```bash
echo "✨ Adding <name> Helm repo"
helm repo add <name> <url>
helm repo update

echo "✨ Creating <tool> namespace"
kubectl create namespace <tool>

echo "✨ Installing <tool> via Helm"
helm install <tool> <repo>/<chart> \
  --version "$version" \
  --namespace <tool> \
  --values "$SCRIPT_DIR/values.yaml" \
  --wait \
  --timeout 5m
```

Keep `values.yaml` minimal — set resource requests/limits, disable unnecessary components,
and configure NodePort if needed. Default to lightweight settings (no persistence, minimal replicas).

## Port Assignments

| Port        | Service                        |
|-------------|--------------------------------|
| 30100       | ArgoCD                         |
| 30101       | Argo Rollouts (port-forward)   |
| 30102       | Prometheus                     |
| 30103       | Jaeger                         |
| 30104       | GCP API Mock (outside cluster) |
| 30105       | Ollama                         |
| 30106       | OpenTelemetry Collector (gRPC) |
| 30107       | OpenTelemetry Collector (HTTP) |
| 30108       | Qdrant (HTTP)                  |
| 30109       | Qdrant (gRPC)                  |
| 30110       | Gitea                          |
| 30111       | Argo Workflows                 |
| 30200–30204 | Custom app (reserved)          |

Notes:
- 30101 is skipped in Kind config — Argo Rollouts dashboard uses port-forward instead
- 30104 is skipped in Kind config — GCP API Mock runs outside the cluster as a Docker container
- Assign the next sequential port to new tools that expose a UI

## Releases

Releases are fully automatic. On every push to `main`, `.github/workflows/release.yml` parses
the commit message and creates a GitHub Release + tag:
- `feat:` → minor bump
- `fix:` → patch bump
- `feat!:` or `BREAKING CHANGE` → major bump

Always use [Conventional Commits](https://www.conventionalcommits.org/) — this is what drives
versioning.

## Distribution

Consumers use the library like this in their `post-create.sh`:

```bash
LIB_DIR=$(mktemp -d)
curl -fsSL "https://github.com/KatharinaSick/devcontainer-lib/archive/refs/tags/${LIB_VERSION}.tar.gz" \
  | tar -xz --strip-components=2 -C "$LIB_DIR"

"$LIB_DIR/gum/init.sh" --version v0.17.0   # always first — other scripts may depend on gum
"$LIB_DIR/kubernetes/init.sh" ...
# ... other tools ...

rm -rf "$LIB_DIR"
```

`lib/gum/init.sh` is the universal baseline and must always be called first.
