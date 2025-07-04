#!/usr/bin/env bash
# shellcheck disable=SC2312
export DETIK_CLIENT_NAMESPACE
export DEPLOYMENT_NAME
export ROCKETCHAT_CHART_DIR
export VALUES_FILE
export DEPLOYMENT_NAME
export HELM_REPO_RELEASE
export ROCKETCHAT_CHART_ARCHIVE
export ROCKETCHAT_TAG
export TESTS_DIR
export HELM_TAG

helm_dry_run() {
  run_and_assert_success helm install \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --create-namespace \
    "${DEPLOYMENT_NAME}" \
    "${ROCKETCHAT_CHART_DIR}" \
    --values "${VALUES}" \
    --dry-run=client
}

helm_install_latest_published_version() {
  run_and_assert_success helm upgrade \
    --install "${DEPLOYMENT_NAME}" \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --create-namespace \
    --values "${VALUES}" \
    --repo "${HELM_REPO_RELEASE}" \
    "rocketchat" \
    --wait \
    --wait-for-jobs \
    --timeout 10m
}

helm_package_chart() {
  run_and_assert_success helm package \
    --app-version "${ROCKETCHAT_TAG}" \
    --version "${HELM_TAG}" \
    "${ROCKETCHAT_CHART_DIR}" \
    -d "$(dirname "${ROCKETCHAT_CHART_ARCHIVE}")"
}

helm_upgrade_to_local_chart() {
  run_and_assert_success helm upgrade \
    "${DEPLOYMENT_NAME}" \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --values "${VALUES}" \
    "${ROCKETCHAT_CHART_ARCHIVE}" \
    --wait \
    --wait-for-jobs \
    --timeout 5m
}

skip_on_mock_server() {
  kubectl get node | grep -iq kwok-node &&
    skip "Skipping test on mock server"
}

test_rocketchat_ingress() {
  args=()
  for arg in "$@"; do
    args+=("rocketchat ${arg}")
  done
  test_ingress_prop "${args[@]}"
}

install_prometheus_operator() {
  run_and_assert_success helm upgrade \
    --install \
    prometheus-operator \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --values "${TESTS_DIR}/../../mock/prometheus-operator/values.yaml" \
    --repo https://prometheus-community.github.io/helm-charts \
    kube-prometheus-stack \
    --wait \
    --timeout 5m
}
