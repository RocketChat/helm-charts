#!/usr/bin/env bash
# shellcheck disable=SC2312

install_mongodb_operator() {
	run_and_assert_success kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/1.6.1/public/crds.yaml
	run_and_assert_success helm repo add mongodb https://mongodb.github.io/helm-charts
	run_and_assert_success helm upgrade --install mongodb-kubernetes-operator mongodb/mongodb-kubernetes \
	--namespace ${DETIK_CLIENT_NAMESPACE} \
	--create-namespace \
	--wait \
	--wait-for-jobs \
	--timeout=5m
}

uninstall_mongodb_operator() {
	run_and_assert_success kubectl delete -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/1.6.1/public/crds.yaml
	run_and_assert_success helm uninstall mongodb-kubernetes-operator -n "${DETIK_CLIENT_NAMESPACE}" --wait --timeout 5m
}

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
    "${ROCKETCHAT_CHART_DIR}" \
	--set=upgradeAcknowledgedAt=$(date +%s) \
    --wait \
    --wait-for-jobs \
    --timeout 5m
  
  sleep 30s
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
