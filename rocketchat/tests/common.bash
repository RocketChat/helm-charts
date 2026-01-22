#!/usr/bin/env bash
# shellcheck disable=SC2312

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
  # Handle NATS upgrade from 0.15.x to 1.3.x
  # The old NATS 0.15.x and new NATS 1.3.x have incompatible StatefulSet configurations
  # We need to delete the old resources completely and let Helm recreate them
  if kubectl get statefulset "${DEPLOYMENT_NAME}-nats" -n "${DETIK_CLIENT_NAMESPACE}" >/dev/null 2>&1; then
    echo "[INFO] Deleting NATS StatefulSet to allow upgrade from 0.15.x to 1.3.x"
    kubectl delete statefulset "${DEPLOYMENT_NAME}-nats" -n "${DETIK_CLIENT_NAMESPACE}" || true
  fi

  if kubectl get deployment "${DEPLOYMENT_NAME}-nats-box" -n "${DETIK_CLIENT_NAMESPACE}" >/dev/null 2>&1; then
    echo "[INFO] Deleting NATS box deployment to allow upgrade"
    kubectl delete deployment "${DEPLOYMENT_NAME}-nats-box" -n "${DETIK_CLIENT_NAMESPACE}" || true
  fi

  # Wait for NATS pods to be fully deleted
  echo "[INFO] Waiting for NATS pods to be deleted..."
  kubectl wait --for=delete pod -l "app.kubernetes.io/name=nats" -n "${DETIK_CLIENT_NAMESPACE}" --timeout=60s || true

  run_and_assert_success helm upgrade \
    "${DEPLOYMENT_NAME}" \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --values "${VALUES}" \
    "${ROCKETCHAT_CHART_DIR}" \
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
    --values "${PROMETHEUS_OPERATOR_VALUES}" \
    --repo https://prometheus-community.github.io/helm-charts \
    kube-prometheus-stack \
    --wait \
    --timeout 5m
}
