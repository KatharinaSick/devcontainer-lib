#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

help() {
  echo "Usage: $0 [OPTIONS] <tool> [tool...]"
  echo "Options:"
  echo " --help                Display this help message"
  echo " --timeout <duration>  Timeout per tool (default: 5m)"
  echo "Tools:"
  echo " argo-events           Waits for Argo Events and installs the default EventBus"
  echo " argo-rollouts         Waits for Argo Rollouts controller"
  echo " argo-workflows        Waits for Argo Workflows server and workflow controller"
  echo " gitea                 Waits for Gitea"
  echo " jaeger                Waits for Jaeger"
  echo " kube-state-metrics    Waits for kube-state-metrics"
  echo " kyverno               Waits for Kyverno admission controller"
  echo " ollama                Waits for Ollama"
  echo " otel-collector        Waits for OTEL Collector"
  echo " prometheus            Waits for standalone Prometheus"
  echo " prometheus-operator   Waits for Prometheus Operator (kube-prometheus-stack)"
  echo " qdrant                Waits for Qdrant"
}

timeout="5m"
tools=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) help; exit 0 ;;
    --timeout)
      if [[ -z "${2-}" ]]; then echo "Error: --timeout requires a value" >&2; exit 1; fi
      timeout="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) tools+=("$1"); shift ;;
  esac
done

if [[ ${#tools[@]} -eq 0 ]]; then
  echo "Error: at least one tool is required" >&2
  exit 1
fi

for tool in "${tools[@]}"; do
  case "$tool" in
    argo-events)
      echo "✨ Waiting for Argo Events"
      kubectl rollout status deployment/argo-events-controller-manager -n argo-events --timeout="$timeout"
      echo "✨ Installing default EventBus (NATS)"
      kubectl apply -f "$SCRIPT_DIR/argo-events/manifests/eventbus.yaml"
      ;;
    argo-rollouts)
      echo "✨ Waiting for Argo Rollouts"
      kubectl rollout status deployment/argo-rollouts -n argo-rollouts --timeout="$timeout"
      ;;
    argo-workflows)
      echo "✨ Waiting for Argo Workflows"
      kubectl rollout status deployment/argo-workflows-server -n argo-workflows --timeout="$timeout"
      kubectl rollout status deployment/argo-workflows-workflow-controller -n argo-workflows --timeout="$timeout"
      ;;
    gitea)
      echo "✨ Waiting for Gitea"
      kubectl rollout status deployment/gitea -n gitea --timeout="$timeout"
      ;;
    jaeger)
      echo "✨ Waiting for Jaeger"
      kubectl rollout status deployment/jaeger -n jaeger --timeout="$timeout"
      ;;
    kube-state-metrics)
      echo "✨ Waiting for kube-state-metrics"
      kubectl rollout status deployment/kube-state-metrics -n kube-state-metrics --timeout="$timeout"
      ;;
    kyverno)
      echo "✨ Waiting for Kyverno"
      kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout="$timeout"
      ;;
    ollama)
      echo "✨ Waiting for Ollama"
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ollama -n ollama --timeout="$timeout"
      ;;
    otel-collector)
      echo "✨ Waiting for OTEL Collector"
      kubectl rollout status deployment/collector -n otel --timeout="$timeout"
      ;;
    prometheus)
      echo "✨ Waiting for Prometheus"
      kubectl rollout status deployment/prometheus-server -n prometheus --timeout="$timeout"
      ;;
    prometheus-operator)
      echo "✨ Waiting for Prometheus Operator"
      kubectl rollout status deployment/prometheus-kube-prometheus-operator -n prometheus --timeout="$timeout"
      kubectl rollout status statefulset/prometheus-prometheus-kube-prometheus-prometheus -n prometheus --timeout="$timeout"
      ;;
    qdrant)
      echo "✨ Waiting for Qdrant"
      kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=qdrant -n qdrant --timeout="$timeout"
      ;;
    *)
      echo "Unknown tool: $tool" >&2
      exit 1
      ;;
  esac
done

echo "✅ All tools are ready"
