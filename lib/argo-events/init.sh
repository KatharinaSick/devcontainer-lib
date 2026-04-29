#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo " --help             Display this help message"
  echo " --version <ver>    Argo Events Helm chart version to install (required)"
}

# Parse flags
version=""

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

echo "✨ Adding Argo Helm repo"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "✨ Creating argo-events namespace"
kubectl create namespace argo-events

echo "✨ Installing Argo Events via Helm"
helm install argo-events argo/argo-events \
  --version "$version" \
  --namespace argo-events \
  --values "$SCRIPT_DIR/values.yaml" \
  --wait \
  --timeout 5m

echo "✨ Installing default EventBus (NATS)"
kubectl apply -f "$SCRIPT_DIR/manifests/eventbus.yaml"

echo "✅ Argo Events is ready"
