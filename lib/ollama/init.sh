#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo " --help                Display this help message"
  echo " --version <ver>       Ollama Helm chart version to install (required)"
  echo " --no-wait             Skip waiting for Ollama to be ready"
  echo " --timeout <duration>  Timeout for wait operations (default: 10m)"
}

# Parse flags
version=""
no_wait=false
timeout="10m"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      help
      exit 0
      ;;
    --version)
      if [[ -z "${2-}" ]]; then
        echo "Error: --version requires a value" >&2
        exit 1
      fi
      version="$2"
      shift 2
      ;;
    --no-wait)
      no_wait=true
      shift
      ;;
    --timeout)
      if [[ -z "${2-}" ]]; then
        echo "Error: --timeout requires a value" >&2
        exit 1
      fi
      timeout="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$version" ]]; then
  echo "Error: --version is required" >&2
  exit 1
fi

# Deploy Ollama to Kubernetes with TinyLlama model pre-loaded

echo "✨ Adding Ollama Helm repo"
helm repo add otwld https://helm.otwld.com/
helm repo update

echo "✨ Installing Ollama via Helm"
helm_args=(
  --version "$version"
  --namespace ollama --create-namespace
  --values "$SCRIPT_DIR/values.yaml"
)
if [[ "$no_wait" == false ]]; then
  helm_args+=(--wait --timeout "$timeout")
fi
helm install ollama otwld/ollama "${helm_args[@]}"

if [[ "$no_wait" == false ]]; then
  echo "✨ Waiting for Ollama to be ready"
  kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ollama -n ollama --timeout="$timeout"
fi

echo "✅ Ollama is ready with TinyLlama model"
