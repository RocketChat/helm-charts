#!/usr/bin/env bash

# shellcheck disable=SC2317

set -euo pipefail

declare -A PORTS

PORTS["mock-rocketchat"]=8080
PORTS["cluster-rocketchat"]=9080
PORTS["mock-monitoring"]=8082
PORTS["cluster-monitoring"]=9082

function _error() {
  for line in "${@}"; do
    echo -e "[ERROR]: ${line}" >&2
  done
  return 1
}

function _warn() {
  for line in "${@}"; do
    echo -e "[WARN]: ${line}" >&2
  done
}

function _info() {
  for line in "${@}"; do
    echo -e "[INFO]: ${line}"
  done
}

function submodules() {
  git submodule update --init --recursive
}

function mock.run() {
  KUBECONFIG_FILE="${KUBECONFIG_FILE:-$(mktemp)}"
  export KWOK_PORT
  KWOK_PORT="${PORTS[${PROJECT_NAME}]}"
  sed "s/8080/${KWOK_PORT}/g" mock/kubeconfig.yaml >"${KUBECONFIG_FILE}"

  # shellcheck disable=SC2329
  function _compose() {
    docker compose \
      --file mock/compose.yaml \
      --project-name "${PROJECT_NAME}" \
      "$@"
  }

  # shellcheck disable=SC2329
  function create() {
    _compose up -d
  }

  # shellcheck disable=SC2329
  function delete() {
    _compose down --volumes --remove-orphans
  }

  "${@}"
}

cluster.run() {
  PROJECT_NAME="${PROJECT_NAME:-${1}}"
  PORT="${PORTS[${PROJECT_NAME}]}"
  KUBECONFIG_FILE="${KUBECONFIG_FILE:-$(mktemp)}"
  local cluster_exists="false"
  # shellcheck disable=SC2329
  function create() {
    k3d cluster create \
      --api-port "${PORT}" \
      --image rancher/k3s:v1.33.2-k3s1 \
      --kubeconfig-switch-context=false \
      --kubeconfig-update-default=false \
      --no-lb \
      "${PROJECT_NAME}" || cluster_exists="true"

    if [[ "${IGNORE_CLEANUP:-}" == "true" && "${cluster_exists}" == "true" ]]; then
      _warn "Cluster ${PROJECT_NAME} already exists, skipping creation."
    elif [[ "${cluster_exists}" == "true" ]]; then
      _error "Failed to create cluster ${PROJECT_NAME}."
    fi

    get_kubeconfig >"${KUBECONFIG_FILE}"
  }

  # shellcheck disable=SC2329
  function get_kubeconfig() {
    k3d kubeconfig get "${PROJECT_NAME}"
  }

  # shellcheck disable=SC2329
  function delete() {
    k3d cluster delete "${PROJECT_NAME}"
  }

  "${@}"
}

function mock() {
  export KUBECONFIG_FILE
  export PROJECT_NAME
  export KUBECONFIG

  KUBECONFIG_FILE="$(mktemp)"
  KUBECONFIG="${KUBECONFIG_FILE}"
  args="$*"
  PROJECT_NAME="mock-${args//\ /-}"
  echo "${PROJECT_NAME}"

  _info \
    "Using project name: ${PROJECT_NAME}" \
    "Using kubeconfig file: ${KUBECONFIG_FILE}"

  [[ -z "${IGNORE_CLEANUP:-}" ]] &&
    trap 'mock.run delete' EXIT

  mock.run create
  "$@"
}

function cluster() {
  export KUBECONFIG_FILE
  export PROJECT_NAME
  export KUBECONFIG

  KUBECONFIG_FILE="$(mktemp)"
  KUBECONFIG="${KUBECONFIG_FILE}"
  args="${*}"

  PROJECT_NAME="cluster-${1}"

  _info \
    "Running tests for ${1} mode" \
    "Using project name: ${PROJECT_NAME}" \
    "Using kubeconfig file: ${KUBECONFIG_FILE}"

  [[ -z "${IGNORE_CLEANUP:-}" ]] &&
    trap 'cluster.run delete' EXIT

  cluster.run create
  "$@"
}

function rocketchat() {
  ./rocketchat/tests/run.bash "$@"
}

function monitoring() {
  ./bats/core/bin/bats ./monitoring/tests/tests.bats "$@"
}

function clean() {
  find . -name "*.tgz" -delete
  for mode in "microservices" "monolith"; do
    PROJECT_NAME="mock-rocketchat-${mode}" \
      mock.run delete || true
    PROJECT_NAME="cluster-rocketchat-${mode}" \
      cluster.run delete || true
  done

  PROJECT_NAME="mock-monitoring" \
    mock.run delete || true
  PROJECT_NAME="cluster-monitoring" \
    cluster.run delete || true

  "$@"
}

function keep() {
  export IGNORE_CLEANUP="true"
  _info "---"
  _info "Resources will be kept after running tests"
  _info "---"
  "$@"
}

function usage() {
  echo "Usage: $0 <command> [args]"
  echo "Available commands:"
  echo "  submodules       - Initialize git submodules"
  echo "  mock             - Run mock tests"
  echo "  cluster          - Run cluster tests"
  echo "  rocketchat       - Run Rocket.Chat tests"
  echo "  monitoring       - Run monitoring tests"
  echo "  clean            - Clean up generated files and resources"
  echo "  keep             - Keep resources after running tests"
  echo "  help             - Show this help message"

  echo "Example usage:"
  echo "  $0 [keep] mock rocketchat"
  echo "  $0 [keep] cluster monitoring"
}


if [[ -z "${1:-}" ]]; then
  _error "$(usage)"
  exit 1
fi

"$@"
