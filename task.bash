#!/usr/bin/env bash

# shellcheck disable=SC2317

set -euo pipefail

declare -A PORTS

PORTS["mock-rocketchat-monolith"]=8080
PORTS["mock-rocketchat-microservices"]=8081
PORTS["cluster-rocketchat-monolith"]=9080
PORTS["cluster-rocketchat-microservices"]=9081
PORTS["mock-monitoring"]=8082
PORTS["cluster-monitoring"]=9082

function _error() {
  for line in "${@}"; do
    echo -e "[ERROR]: ${line}" >&2
  done
  return 1
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

  function _compose() {
    docker compose \
      --file mock/compose.yaml \
      --project-name "${PROJECT_NAME}" \
      "$@"
  }

  function create() {
    _compose up -d
  }

  function delete() {
    _compose down --volumes --remove-orphans
  }

  "${@}"
}

cluster.run() {
  PROJECT_NAME="${PROJECT_NAME:-${1}}"
  PORT="${PORTS[${PROJECT_NAME}]}"
  KUBECONFIG_FILE="${KUBECONFIG_FILE:-$(mktemp)}"

  function create() {
    k3d cluster create \
      --api-port "${PORT}" \
      --image rancher/k3s:v1.33.2-k3s1 \
      --kubeconfig-switch-context=false \
      --kubeconfig-update-default=false \
      --no-lb \
      "${PROJECT_NAME}"

    get_kubeconfig >"${KUBECONFIG_FILE}"
  }

  function get_kubeconfig() {
    k3d kubeconfig get "${PROJECT_NAME}"
  }

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

  PROJECT_NAME="cluster-${args// /-}"

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
  modes=("microservices" "monolith")

  MODE="${1}"
  shift

  [[ ! " ${modes[*]} " =~ ${MODE} ]] && {
    _error \
      "Invalid mode: ${MODE}" \
      "Valid modes: ${modes[*]}"
    return 1
  }

  ./rocketchat/tests/run.bash "${MODE}" "$@"
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
  "$@"
}

"$@"
