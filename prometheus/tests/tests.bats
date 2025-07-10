#!/bin/bash

load "../../bats/common.sh"
load "../../bats/kubernetes_common.sh"
load "common.bash"

export DETIK_CLIENT_NAME="kubectl"

# export DEBUG_DETIK="true"
setup_file() {
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-prometheus-operator}"
  export HELM_TAG="${HELM_TAG:-0.0.0}"
  export DETIK_CLIENT_NAMESPACE="bats-${DEPLOYMENT_NAME}"

  export BATS_TMPDIR
  BATS_TMPDIR="$(mktemp -d)"
  TESTS_DIR="$(dirname "${BATS_TEST_FILENAME}")"
  export CHART_DIR="${TESTS_DIR}/../../prometheus"
  export POD_RETRIES="${POD_RETRIES:-5}"
  export POD_RETRY_INTERVAL="${POD_RETRY_INTERVAL:-60}"
  export VALUES="${BATS_TMPDIR}/values.yaml"
  export CHART_ARCHIVE="${BATS_TMPDIR}/prometheus-${HELM_TAG}.tgz"

  info_message \
    "Bats tmpdir: ${BATS_TMPDIR}" \
    "Test dir: ${TESTS_DIR}" \
    "Pod retries: ${POD_RETRIES}" \
    "Pod retry interval: ${POD_RETRY_INTERVAL}" \
    "Values: ${VALUES}" \
    "KUBECONFIG: ${KUBECONFIG}" \
    "PWD: $(pwd)"
  envsubst <"$TESTS_DIR/values.yaml" >"$VALUES"
}

helm_common() {
  # helm_common upgrade|install <other args>
  helm \
    "$1" \
    "$DEPLOYMENT_NAME" \
    --namespace "$DETIK_CLIENT_NAMESPACE" \
    --create-namespace \
    --values "$VALUES" \
    --wait \
    --timeout 600s \
    "${CHART_ARCHIVE}"
}

# bats test_tags=pre,deploy
@test "verify dependency install" {
  [[ -f "$CHART_ARCHIVE" ]] &&
    skip "chart package already exists"
  run_and_assert_success helm dependency update "$CHART_DIR"
}

# bats test_tags=pre,deploy
@test "verify packaging chart" {
  [[ -f "$CHART_ARCHIVE" ]] &&
    skip "chart package already exists"

  run_and_assert_success helm package \
    --version "$HELM_TAG" \
    "${CHART_DIR}" \
    -d "$(dirname "$CHART_ARCHIVE")"

  assert [ -f "$CHART_ARCHIVE" ]
}

# bats test_tags=pre
@test "verify chart --dry-run" {
  helm --namespace "$DETIK_CLIENT_NAMESPACE" \
    ls | grep -q "$DEPLOYMENT_NAME" &&
    skip "Chart already installed, skipping dry-run test"
  run_and_assert_success helm_common install \
    --dry-run=client \
    --debug

  # Verify that the chart archive is not created during dry-run
}

# bats test_tags=deploy
@test "deploy chart" {
  run_and_assert_success helm_common \
    upgrade \
    --install
}

# bats test_tags=asserts
@test "assert ingress" {
  run_and_assert_success test_ingress_prop \
    "ingress .spec.rules[0].host is grafana.example.com" \
    "ingress .spec.rules[0].host is prometheus.example.com" \
    "ingress .spec.rules[0].http.paths[0].path is /"
}

# bats test_tags=asserts, dashboards
@test "assert dashboards" {
  test_dashboards() {
    dashboard="${1}"
    run_and_assert_success verify "\
      there is 1 grafanadashboards.grafana.integreatly.org named '^${DEPLOYMENT_NAME}-${dashboard}$'"
  }

  test_dashboards kubernetes-deployment
  test_dashboards kubernetes-node
  test_dashboards kubernetes-pod
  test_dashboards node-exporter-full
  test_dashboards rocketchat-metrics
  test_dashboards rocketchat-microservices
}
# bats test_tags=cleanup
@test "cleanup" {
  [[ -n "$IGNORE_CLEANUP" ]] &&
    skip "Skipping cleanup due to IGNORE_CLEANUP"

  helm uninstall \
    --namespace "$DETIK_CLIENT_NAMESPACE" \
    "$DEPLOYMENT_NAME"
}
