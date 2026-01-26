#!/usr/bin/env bash
# shellcheck disable=SC2312

install_mongodb_operator() {
	kubectl get deploy -n mongodb-kubernetes-operator | grep -q mongodb-kubernetes-operator \
		&& skip "mongodb operator already installed"

	run_and_assert_success kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/1.6.1/public/crds.yaml
	run_and_assert_success helm upgrade \
		--install mongodb-kubernetes-operator \
		mongodb-kubernetes \
		--namespace mongodb-kubernetes-operator \
		--repo https://mongodb.github.io/helm-charts \
		--create-namespace \
		--wait \
		--wait-for-jobs \
		--timeout=5m \
		--set "operator.watchNamespace=*"
}

uninstall_mongodb_operator() {
	run_and_assert_success kubectl delete -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes/1.6.1/public/crds.yaml
	run_and_assert_success helm uninstall mongodb-kubernetes-operator -n "${DETIK_CLIENT_NAMESPACE}" --wait --timeout 5m
}

install_mongodb_cluster() {
	(
		run_and_assert_success cd "$(git rev-parse --show-toplevel)" || exit 1
		cat mock/manifests/mongodbcommunity.yaml | envsubst | run_and_assert_success kubectl apply -f - -n ${DETIK_CLIENT_NAMESPACE} || exit 1
		
		sleep 30s
	)
}

uninstall_mongodb_cluster() {
	(
		run_and_assert_success cd "$(git rev-parse --show-toplevel)" || exit 1
		cat mock/manifests/mongodbcommunity.yaml | envsubst | run_and_assert_success kubectl delete -f - -n ${DETIK_CLIENT_NAMESPACE} || exit 1
	)
}

helm_dry_run() {
  run_and_assert_success helm install \
    --namespace "${DETIK_CLIENT_NAMESPACE}" \
    --create-namespace \
    "${DEPLOYMENT_NAME}" \
    "${ROCKETCHAT_CHART_DIR}" \
    --values "${VALUES}" \
	--set "externalMongodbUrl=mongodb://rocketchat:rocketchat-password@${DEPLOYMENT_NAME}-mongodb-svc.${DETIK_CLIENT_NAMESPACE}.svc.cluster.local:27017/rocketchat?authSource=rocketchat&replicaSet=${DEPLOYMENT_NAME}-mongodb" \
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
	--set "externalMongodbUrl=mongodb://rocketchat:rocketchat-password@${DEPLOYMENT_NAME}-mongodb-svc.${DETIK_CLIENT_NAMESPACE}.svc.cluster.local:27017/rocketchat?authSource=rocketchat&replicaSet=${DEPLOYMENT_NAME}-mongodb" \
    --timeout 10m \
	"--set=upgradeAcknowledgedAt=$(date +%s)"
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
	--set "externalMongodbUrl=mongodb://rocketchat:rocketchat-password@${DEPLOYMENT_NAME}-mongodb-svc.${DETIK_CLIENT_NAMESPACE}.svc.cluster.local:27017/rocketchat?authSource=rocketchat&replicaSet=${DEPLLOYMENT_NAME}-mongodb" \
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
  helm ls -n "prometheus-operator" | grep -q "prometheus-operator" &&
	skip "prometheus-operator already installed"
  run_and_assert_success helm upgrade \
    --install \
    kube-prometheus-stack \
    --namespace "prometheus-operator" \
	--create-namespace \
    --repo https://prometheus-community.github.io/helm-charts \
    kube-prometheus-stack \
    --wait \
    --timeout 5m \
	--set global.rbac.create=true \
	--set crds.enabled=true \
	--set defaultRules.createfalse \
	--set windowsMonitoring.enabled=false \
	--set alertmanager.enabled=false \
	--set grafana.enabled=false \
	--set kubernetesServiceMonitors.enabled=false \
	--set kubeApiServer.enabled=false \
	--set kubelet.enabled=false \
	--set kubeControllerManager.enabled=false \
	--set coreDns.enabled=false \
	--set kubeDns.enabled=false \
	--set kubeEtcd.enabled=false \
	--set kubeScheduler.enabled=false \
	--set kubeProxy.enabled=false \
	--set kubeStateMetrics.enabled=false \
	--set nodeExporter.enabled=false \
	--set prometheus.enabled=false \
	--set prometheusOperator.enabled=true \
	--set cleanPrometheusOperatorObjectNames=false \
	--set extraManifests=null
}
