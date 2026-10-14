#!/bin/bash

load "../../bats/common.sh"
load "../../bats/kubernetes_common.sh"

export DETIK_CLIENT_NAME="kubectl"

# export DEBUG_DETIK="true"
setup_file() {
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-bats}"
  export HELM_TAG="${HELM_TAG:-0.0.0}"
  export LIVEKIT_HOST="${LIVEKIT_HOST:-livekit.example.com}"
  export DETIK_CLIENT_NAMESPACE="bats-rocketchat-livekit"

  export BATS_TMPDIR
  BATS_TMPDIR="$(mktemp -d)"
  TESTS_DIR="$(dirname "${BATS_TEST_FILENAME}")"
  export CHART_DIR="${TESTS_DIR}/.."
  export POD_RETRIES="${POD_RETRIES:-5}"
  export POD_RETRY_INTERVAL="${POD_RETRY_INTERVAL:-60}"
  export VALUES="${BATS_TMPDIR}/values.yaml"
  export CHART_ARCHIVE="${BATS_TMPDIR}/rocketchat-livekit-${HELM_TAG}.tgz"
  export FULLNAME="${DEPLOYMENT_NAME}-rocketchat-livekit"

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
    "${@:2}" \
    "${CHART_ARCHIVE}"
}

secret_value() {
  kubectl --namespace "$DETIK_CLIENT_NAMESPACE" \
    get secret livekit-credentials \
    --output "jsonpath={.data.${1}}" | base64 -d
}

is_mock() {
  [[ "${PROJECT_NAME:-}" == mock-* ]]
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
}

# bats test_tags=pre
@test "verify launchcontrol-style string values" {
  # launchcontrol hands every value over as a string, "false" included.
  run helm template "$DEPLOYMENT_NAME" "$CHART_ARCHIVE" \
    --set-string 'host=livekit.{{ .Values.launchcontrol.workspaceName }}.example.com' \
    --set-string launchcontrol.workspaceName=acme \
    --set-string ingress.enabled=false \
    --set-string monitoring.prometheus.enabled=false \
    --set-string media.tcp.enabled=true \
    --set-string media.udpPort=7882
  assert_success
  assert_output --partial 'url: "wss://livekit.acme.example.com"'
  assert_output --partial 'tcp_port: 7881'
  assert_output --partial 'udp_port: 7882'
  refute_output --partial 'kind: Ingress'
  refute_output --partial 'prometheus'
}

# bats test_tags=pre
@test "verify short api secrets are refused" {
  run helm template "$DEPLOYMENT_NAME" "$CHART_ARCHIVE" \
    --set credentials.apiSecret=tooshort
  assert_failure
  assert_output --partial "at least 32 characters"
}

# bats test_tags=deploy
@test "deploy chart" {
  run_and_assert_success helm_common \
    upgrade \
    --install
}

# bats test_tags=asserts
@test "assert deployment" {
  test_deploys rocketchat-livekit
}

# bats test_tags=asserts
@test "assert services" {
  test_services rocketchat-livekit rocketchat-livekit-media
}

# bats test_tags=asserts
@test "assert ingress" {
  run_and_assert_success test_ingress_prop \
    "rocketchat-livekit .spec.rules[0].host is ${LIVEKIT_HOST}" \
    "rocketchat-livekit .spec.rules[0].http.paths[0].path is /"
}

# bats test_tags=asserts
@test "assert credentials" {
  run secret_value url
  assert_output "wss://${LIVEKIT_HOST}"

  run secret_value apiKey
  assert_output --regexp '^API[A-Za-z0-9]{12}$'

  run secret_value apiSecret
  assert_output --regexp '^[A-Za-z0-9]{48}$'
}

# bats test_tags=asserts
@test "assert credentials survive an upgrade" {
  api_key="$(secret_value apiKey)"
  api_secret="$(secret_value apiSecret)"

  run_and_assert_success helm_common upgrade

  run secret_value apiKey
  assert_output "$api_key"
  run secret_value apiSecret
  assert_output "$api_secret"
}

# bats test_tags=asserts
@test "assert livekit advertises the resolved media address" {
  is_mock && skip "pods don't run on the mock cluster"

  run kubectl --namespace "$DETIK_CLIENT_NAMESPACE" \
    logs "deployment/${FULLNAME}"
  assert_success
  assert_output --regexp 'Advertising [0-9.]+ \(kubernetes\.default\.svc\.cluster\.local\) to clients'
  assert_output --partial '"nodeIP"'
}

# bats test_tags=asserts
@test "assert livekit answers" {
  is_mock && skip "pods don't run on the mock cluster"

  run kubectl --namespace "$DETIK_CLIENT_NAMESPACE" \
    run "curl-${BATS_TEST_NUMBER}" \
    --image curlimages/curl:8.11.1 \
    --restart Never \
    --rm \
    --attach \
    --quiet \
    -- curl -sS --max-time 10 "http://${FULLNAME}:7880/"
  assert_success
  assert_output --partial OK
}

# bats test_tags=cleanup
@test "cleanup" {
  [[ -n "${IGNORE_CLEANUP:-}" ]] &&
    skip "Skipping cleanup due to IGNORE_CLEANUP"

  helm uninstall \
    --namespace "$DETIK_CLIENT_NAMESPACE" \
    "$DEPLOYMENT_NAME"

  # Kept on uninstall on purpose (helm.sh/resource-policy: keep)
  run kubectl --namespace "$DETIK_CLIENT_NAMESPACE" \
    get secret livekit-credentials
  assert_success

  kubectl --namespace "$DETIK_CLIENT_NAMESPACE" \
    delete secret livekit-credentials
}
