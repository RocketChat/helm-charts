#!/usr/bin/env bash
# shellcheck disable=SC2317

set -euo pipefail

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

function kwok.run() {
  KWOK_PORT="${KWOK_PORT:-8080}"
  KUBECONFIG_FILE="${KUBECONFIG_FILE:-$(mktemp)}"
  PROJECT_NAME="${PROJECT_NAME:-${1}}"

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

kind.run() {
  PROJECT_NAME="${PROJECT_NAME:-${1}}"

  function create() {
    kind create cluster --name "${PROJECT_NAME}" || true
  }

  function delete() {
    kind delete cluster --name "${PROJECT_NAME}"
  }

  "${@}"
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

  _run_tests() {
    ./rocketchat/tests/run.bash "${MODE}"
  }

  KUBECONFIG_FILE="$(mktemp)"

  function mock() {
    export PROJECT_NAME="kwok-${MODE}"
    export KUBECONFIG="${KUBECONFIG_FILE}"

    if [[ "${MODE}" == "microservices" ]]; then
      port="8081"
    else
      port="8080"
    fi

    export KWOK_PORT="${port}"

    # Set up cleanup trap to ensure kwok.run delete always runs
    [[ -z "${IGNORE_CLEANUP:-}" ]] &&
      trap 'kwok.run delete' EXIT

    kwok.run create
    _run_tests
  }

  function cluster() {
    export PROJECT_NAME="kind-${MODE}"
    unset KUBECONFIG || true

    [[ -z "${IGNORE_CLEANUP:-}" ]] &&
      trap 'kind.run delete' EXIT

    kind.run create
    _run_tests
  }

  "$@"
}

function clean() {
  find . -name "*.tgz" -delete
  "$@"
}

"$@"
