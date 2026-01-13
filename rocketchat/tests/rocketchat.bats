#!/bin/bash

load "../../bats/common.sh"
load "../../bats/kubernetes_common.sh"
load "common.bash"

export DETIK_CLIENT_NAME="kubectl"

# export DEBUG_DETIK="true"

setup_file() {
  export DEPLOYMENT_NAME="${DEPLOYMENT_NAME}"
  export ROCKETCHAT_HOST=${ROCKETCHAT_HOST:-rocketchat.local}
  export ROCKETCHAT_TAG=${ROCKETCHAT_TAG:-7.7.4}
  export ROCKETCHAT_CHART_DIR=${ROCKETCHAT_CHART_DIR:-$(realpath rocketchat)}
  export HELM_TAG="${HELM_TAG:-0.0.0}"
  export ROCKETCHAT_CHART_ARCHIVE="${ROCKETCHAT_CHART_DIR%/}/rocketchat-${HELM_TAG}.tgz"

  export BATS_TMPDIR="$(mktemp -d)"

  export TESTS_DIR="$(dirname "${BATS_TEST_FILENAME}")"
  export HELM_REPO_RELEASE="https://rocketchat.github.io/helm-charts"
  export POD_RETRIES="${POD_RETRIES:-5}"
  export POD_RETRY_INTERVAL="${POD_RETRY_INTERVAL:-60}"
  export VALUES="${BATS_TMPDIR}/values.yaml"
  export PROMETHEUS_OPERATOR_VALUES="${TESTS_DIR}/../../mock/prometheus-operator/values.yaml"
  export DETIK_CLIENT_NAMESPACE="bats-${DEPLOYMENT_NAME}"

  info_message \
    "Values file: ${VALUES_FILE}" \
    "Bats tmpdir: ${BATS_TMPDIR}" \
    "Test dir: ${TESTS_DIR}" \
    "Helm repo release: ${HELM_REPO_RELEASE}" \
    "Pod retries: ${POD_RETRIES}" \
    "Pod retry interval: ${POD_RETRY_INTERVAL}" \
    "Values file: ${VALUES_FILE}" \
    "Values: ${VALUES}" \
    "Prometheus operator values: ${PROMETHEUS_OPERATOR_VALUES}" \
    "PWD: $(pwd)" \
    "KUBECONFIG: ${KUBECONFIG:-}"

  envsubst <"$TESTS_DIR/${VALUES_FILE}" >"$VALUES"

}

# bats test_tags=pre,deploy
@test "sanity check" {
  debug_message_on_failure \
    "PWD: $(pwd)" \
    "VALUES: ${VALUES}" \
    "PROMETHEUS_OPERATOR_VALUES: ${PROMETHEUS_OPERATOR_VALUES}" \
    "ROCKETCHAT_CHART_DIR: ${ROCKETCHAT_CHART_DIR}" \
    "ROCKETCHAT_CHART_ARCHIVE: ${ROCKETCHAT_CHART_ARCHIVE}"

  assert [ -n "${DEPLOYMENT_NAME}" ]
  assert [ -f "${VALUES}" ]
  assert [ -f "${PROMETHEUS_OPERATOR_VALUES}" ]
  [[ "${POD_RETRY_INTERVAL}" =~ ^[0-9]+$ ]] ||
    fail "POD_RETRY_INTERVAL is not a number"
}

# bats test_tags=pre,deploy
@test "verify dependency install" {
  run_and_assert_success helm dependency update "$ROCKETCHAT_CHART_DIR"
}

# bats test_tags=pre
@test "lint chart" {
  run_and_assert_success helm lint --values "$VALUES" "$ROCKETCHAT_CHART_DIR"
}

# bats test_tags=pre
@test "verify packaging chart" {
  [[ -f "$ROCKETCHAT_CHART_ARCHIVE" ]] &&
    skip "chart package already exists"

  run_and_assert_success helm package \
    --app-version "$ROCKETCHAT_TAG" \
    --version "$HELM_TAG" \
    "${ROCKETCHAT_CHART_DIR}" \
    -d "$(dirname "$ROCKETCHAT_CHART_ARCHIVE")"

  assert [ -f "$ROCKETCHAT_CHART_ARCHIVE" ]
}

# bats test_tags=pre,deploy
@test "verify install mongodb operator" {
	kubectl get deployments -n "$DETIK_CLIENT_NAMESPACE" | grep -q "mongodb-kubernetes-operator" && skip "operator already installed"
	
	setup_mongodb_operator
}


# bats test_tags=pre,deploy
@test "verify chart --dry-run" {
  helm_dry_run
}

# bats test_tags=deploy
@test "install latest published version" {
  helm ls | grep -q rocketchat-0.0.0 &&
    skip "upgrade already installed"
  helm_install_latest_published_version
}

# bats test_tags=deploy,microservices
@test "verify upgrade to local chart" {
  helm_upgrade_to_local_chart
}

# bats test_tags=assertion,microservices
@test "verify all services are up for microservices" {
  test_services \
    "mongodb-svc" \
    "presence" \
    "authorization" \
    "stream-hub" \
    "account" \
    "ddp-streamer" \
    "rocketchat" \
    "nats"
}

# bats test_tags=assertion,monolith
@test "verify all services are up for monolith" {
  test_services \
    "mongodb-svc" \
    "rocketchat" \
    "rocketchat-bridge" \
    "rocketchat-synapse"
}

# bats test_tags=assertion,microservices
@test "verify all deployments are up for microservices" {
  test_deploys \
    "nats-box" \
    "rocketchat" \
    "presence" \
    "authorization" \
    "stream-hub" \
    "account" \
    "ddp-streamer"
}
# bats test_tags=assertion,monolith
@test "verify all deployments are up for monolith" {
  test_deploys \
    "rocketchat" \
    "rocketchat-synapse"
}

# bats test_tags=assertion,microservices
@test "verify all individual pods exist for microservices" {
  test_pods \
    "mongodb" \
    "nats" \
    "rocketchat" \
    "nats-box" \
    "presence" \
    "authorization" \
    "stream-hub" \
    "account" \
    "ddp-streamer"
}

# bats test_tags=assertion,monolith
@test "verify all individual pods exist for monolith" {
  test_pods \
    "mongodb-0" \
    "rocketchat" \
    "rocketchat-synapse"
}

# bats test_tags=assertion,microservices
@test "verify all endpointslices microservices' configs" {
  test_endpoint_slice \
    "mongodb-svc mongodb,prometheus 27017,9216" \
    "presence metrics 9458" \
    "authorization metrics 9458" \
    "stream-hub metrics 9458" \
    "account metrics 9458" \
    "ddp-streamer metrics,http 9458,3000" \
    "rocketchat metrics,http 9100,3000" \
    "rocketchat-monolith-ms-metrics moleculer-metrics 9458" \
    "nats monitor,gateways,cluster,client,metrics,leafnodes 8222,7522,6222,4222,7777,7422" \
    "nats-metrics monitor 8222"
}

# bats test_tags=assertion,monolith
@test "verify all endpointslices' configs for monolith" {
  test_endpoint_slice \
    "mongodb-svc mongodb,prometheus 27017,9216" \
    "rocketchat metrics,http 9100,3000" \
    "rocketchat-bridge http 3300" \
    "rocketchat-synapse http 8008"
}

# bats test_tags=assertion,microservices
@test "verify ingress config for microservices" {

  test_rocketchat_ingress \
    ".spec.rules[0].host is $ROCKETCHAT_HOST" \
    ".spec.rules[*].http.paths[*].pathType matches Prefix" \
    ".spec.rules[*].host matches $ROCKETCHAT_HOST|synapse.$ROCKETCHAT_HOST" \
    ".spec.rules[*].http.paths[*].backend.service.name matches $DEPLOYMENT_NAME-rocketchat" \
    ".spec.rules[*].http.paths[*].backend.service.port.name matches http" \
    ".spec.rules[*].http.paths[*].path matches /" \
    ".spec.rules[*].http.paths[*].path matches /sockjs" \
    ".spec.rules[*].http.paths[*].path matches /websocket" \
    ".spec.rules[*].http.paths[*].path matches /.well-known/matrix/server" \
    ".spec.rules[*].http.paths[*].path matches /.well-known/matrix/client"
}

# bats test_tags=assertion,monolith
@test "verify ingress config for monolith" {
  test_rocketchat_ingress \
    ".spec.rules[*].host matches $ROCKETCHAT_HOST|synapse.$ROCKETCHAT_HOST" \
    ".spec.rules[0].host matches synapse.$ROCKETCHAT_HOST" \
    ".spec.rules[*].http.paths[*].pathType matches Prefix" \
    ".spec.rules[*].http.paths[*].path matches /"

}

# bats test_tags=assertion,microservices,monolith
@test "verify secret resources and their values" {
  skip_on_mock_server
  export DETIK_CASE_INSENSITIVE_PROPERTIES="false"
  # regex matching is must for strict verification
  # otherwie base64 values won't match
  local \
    root_password="$(printf "root" | base64)" \
    password="$(printf "rocketchat" | base64)"

  run_and_assert_success verify "\
    '.data.mongodb-passwords' matches '^$password\$' \
    for secret named '${DEPLOYMENT_NAME}-mongodb' \
    "

  run_and_assert_success verify "\
    '.data.mongodb-root-password' matches '^$root_password\$' \
    for secret named '${DEPLOYMENT_NAME}-mongodb' \
    "

  local \
    mongo_uri="$(printf "mongodb://rocketchat:rocketchat@%s-mongodb:27017/rocketchat?replicaSet=rs0" "$DEPLOYMENT_NAME" | base64)" \
    mongo_oplog_uri="$(printf "mongodb://root:root@%s-mongodb:27017/local?replicaSet=rs0&authSource=admin" "$DEPLOYMENT_NAME" | base64)"

  run_and_assert_success verify "\
    '.data.mongo-uri' matches '^$mongo_uri\$' \
    for secret named '${DEPLOYMENT_NAME}-rocketchat' \
    "

  run_and_assert_success verify "\
    '.data.mongo-oplog-uri' matches '^$mongo_oplog_uri\$' \
    for secret named '${DEPLOYMENT_NAME}-rocketchat' \
    "
}

# bats test_tags=assertion,microservices,monolith
@test "verify configmap resources exist" {
  skip_on_mock_server
  run_and_assert_success verify \
    "there is 1 configmap named '${DEPLOYMENT_NAME}-mongodb-fix-clustermonitor-role-configmap'"

  run_and_assert_success verify "\
    there is 1 configmap named '${DEPLOYMENT_NAME}-rocketchat-scripts'"
}

# bats test_tags=operator
@test "install prometheus operator" {
  install_prometheus_operator
}

# bats test_tags=operator
@test "verify prometheus operator is installed" {
  run_and_assert_success verify "there is 1 pod named 'prometheus-operator'"
}

# bats test_tags=operator
@test "upgrade to install podmonitors and servicemonitors" {
  helm_upgrade_to_local_chart
}

# bats test_tags=assertion,operator
@test "verify podmonitor is created" {
  run_and_assert_success verify "there is 1 podmonitor named '${DEPLOYMENT_NAME}-nats'"
  run_and_assert_success verify "there is 1 podmonitor named '${DEPLOYMENT_NAME}-rocketchat'"
  run_and_assert_success verify "there is 0 service named '${DEPLOYMENT_NAME}-nats-metrics'"
}

# bats test_tags=assertion,operator
@test "verify servicemonitor is created" {
  run_and_assert_success verify "there is 1 servicemonitor named '${DEPLOYMENT_NAME}-mongodb'"
}

# bats test_tags=cleanup
@test "cleanup" {
  [[ -n "${IGNORE_CLEANUP:-}" ]] &&
    skip "cleanup is disabled"
  run_and_assert_success helm uninstall \
    "$DEPLOYMENT_NAME" \
    -n "$DETIK_CLIENT_NAMESPACE" \
    --wait \
    --timeout 5m
  run_and_assert_success helm uninstall \
    prometheus-operator \
    -n "$DETIK_CLIENT_NAMESPACE" \
    --wait \
    --timeout 5m

  run_and_assert_success kubectl delete namespace "$DETIK_CLIENT_NAMESPACE"
  run_and_assert_success kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
  run_and_assert_success kubectl delete crd alertmanagers.monitoring.coreos.com
  run_and_assert_success kubectl delete crd podmonitors.monitoring.coreos.com
  run_and_assert_success kubectl delete crd probes.monitoring.coreos.com
  run_and_assert_success kubectl delete crd prometheusagents.monitoring.coreos.com
  run_and_assert_success kubectl delete crd prometheuses.monitoring.coreos.com
  run_and_assert_success kubectl delete crd prometheusrules.monitoring.coreos.com
  run_and_assert_success kubectl delete crd scrapeconfigs.monitoring.coreos.com
  run_and_assert_success kubectl delete crd servicemonitors.monitoring.coreos.com
  run_and_assert_success kubectl delete crd thanosrulers.monitoring.coreos.com
}
