#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

help() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo " --help                Display this help message"
  echo " --operator            Install Prometheus Operator instead of standalone Prometheus"
  echo " --version <ver>       Helm chart version to install (required)"
  echo " --no-wait             Skip waiting for Prometheus to be ready"
  echo " --timeout <duration>  Timeout for wait operations (default: 5m)"
}

# Parse flags
use_operator=false
version=""
no_wait=false
timeout="5m"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      help
      exit 0
      ;;
    --operator)
      use_operator=true
      shift
      ;;
    --no-wait)
      no_wait=true
      shift
      ;;
    --version)
      if [[ -z "${2-}" ]]; then
        echo "Error: --version requires a value" >&2
        exit 1
      fi
      version="$2"
      shift 2
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

# Use a minimal Prometheus setup instead of kube-prometheus-stack to keep the Codespace lightweight and focused.

if [[ -z "$version" ]]; then
  echo "Error: --version is required" >&2
  exit 1
fi

echo "✨ Adding prometheus-community Helm repo"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update

echo "✨ Creating prometheus namespace"
kubectl create namespace prometheus

helm_args=(
  --version "$version"
  --namespace prometheus
)
if [[ "$no_wait" == false ]]; then
  helm_args+=(--wait --timeout "$timeout")
fi

if [ "$use_operator" = true ]; then
  echo "✨ Installing Prometheus Operator (kube-prometheus-stack)"
  helm install prometheus prometheus-community/kube-prometheus-stack \
    "${helm_args[@]}" \
    --values "$SCRIPT_DIR/operator-values.yaml"

  echo "✅ Prometheus Operator is ready"
  echo "💡 Use PrometheusRule CRDs to define recording and alerting rules"
else
  echo "✨ Installing standalone Prometheus"
  helm install prometheus prometheus-community/prometheus \
    "${helm_args[@]}" \
    --values "$SCRIPT_DIR/standalone-values.yaml"

  echo "✅ Prometheus is ready"
fi
