#!/usr/bin/env bash
# shellcheck disable=SC2312,SC2250

# Global environment variables used by test functions
export DETIK_CLIENT_NAMESPACE # Kubernetes namespace for testing
export DEPLOYMENT_NAME        # Base name for the deployment
export POD_RETRIES            # Number of retry attempts for pod operations
export POD_RETRY_INTERVAL     # Interval between retries in seconds

# 1.33 deprecated endpoints and suggests endpointslices instead
test_endpoint_slice() {
  # Test the existence and configuration of Kubernetes EndpointSlices
  #
  # This function verifies that EndpointSlices exist for specified services
  # and have the correct port configurations. It uses the DETIK testing framework
  # to perform assertions with retry logic.
  #
  # Arguments:
  #   $@ - Variable number of space-separated strings, each containing:
  #        - service_name: The name of the service (e.g., "mongodb-headless")
  #        - port_names: Comma-separated list of port names (e.g., "mongodb")
  #        - port_numbers: Comma-separated list of port numbers (e.g., "27017")
  #
  # Example:
  #   test_endpoint_slice "mongodb-headless mongodb 27017" "redis-headless redis 6379"
  #
  # Returns:
  #   0 on success, non-zero on failure
  #   Outputs debug information on failure including current EndpointSlices

  debug_message_on_failure \
    "Found EndpointSlices:" \
    "$(kubectl get endpointslices -n "${DETIK_CLIENT_NAMESPACE}" -o wide)"
  for arg in "$@"; do

    mapfile -d ' ' -t arg_array <<<"${arg}"
    service="${arg_array[0]}"
    port_names="${arg_array[1]}"
    port_numbers="${arg_array[2]}"
    # mapfile -d ',' -t port_numbers <<<"${port_numbers_comma}"
    # mapfile -d ',' -t port_names <<<"${port_names_comma}"

    name_regex="^${DEPLOYMENT_NAME}-${service}-[0-9a-z]{5}\b"

    # for port_name in "${port_names[@]}"; do
    run_and_assert_success try "\
        at most ${POD_RETRIES} times every ${POD_RETRY_INTERVAL}s \
        to find 1 EndpointSlice named '${name_regex}' \
        with '.ports[*].name' being '${port_names}' \
      "
    # done

    # for port_number in "${port_numbers[@]}"; do
    run_and_assert_success try "\
        at most ${POD_RETRIES} times every ${POD_RETRY_INTERVAL}s \
        to find 1 EndpointSlice named '${name_regex}' \
        with '.ports[*].port' being '${port_numbers}' \
      "
    # done

  done
}

test_pods() {
  # Test the status of Kubernetes pods
  #
  # This function verifies that specified pods exist and are in a healthy state
  # (Running or Succeeded). It uses the DETIK testing framework with retry logic
  # to handle pod startup delays.
  #
  # Arguments:
  #   $@ - Variable number of pod names to test. Each pod name should be
  #        the suffix part (without the deployment prefix) that will be
  #        combined with DEPLOYMENT_NAME to form the full pod name.
  #
  # Example:
  #   test_pods "rocketchat-0" "rocketchat-1" "mongodb-0"
  #   # Tests pods: ${DEPLOYMENT_NAME}-rocketchat-0, ${DEPLOYMENT_NAME}-rocketchat-1, etc.
  #
  # Returns:
  #   0 on success, non-zero on failure
  #   Outputs debug information on failure including current pod status

  local pods=("${@}")

  debug_message_on_failure \
    "Pods:" \
    "$(kubectl get pods -n "${DETIK_CLIENT_NAMESPACE}" -o wide)"

  for pod in "${pods[@]}"; do
    run_and_assert_success try "\
      at most ${POD_RETRIES} times every ${POD_RETRY_INTERVAL}s \
      to get pods named '^${DEPLOYMENT_NAME}-${pod}\b' \
      and verify that 'status' matches 'Running|Succeeded' \
    "
  done
}

test_deploys() {
  # Test the status of Kubernetes deployments
  #
  # This function verifies that specified deployments exist and have available
  # replicas (at least 1). It uses the DETIK testing framework with retry logic
  # to handle deployment rollout delays.
  #
  # Arguments:
  #   $@ - Variable number of deployment names to test. Each deployment name
  #        should be the suffix part (without the deployment prefix) that will
  #        be combined with DEPLOYMENT_NAME to form the full deployment name.
  #
  # Example:
  #   test_deploys "rocketchat" "mongodb" "redis"
  #   # Tests deployments: ${DEPLOYMENT_NAME}-rocketchat, ${DEPLOYMENT_NAME}-mongodb, etc.
  #
  # Returns:
  #   0 on success, non-zero on failure
  #   Outputs debug information on failure including current deployment status

  local deploys=("${@}")

  debug_message_on_failure \
    "Deploys:" \
    "$(kubectl get deployments -n "${DETIK_CLIENT_NAMESPACE}" -o wide)"

  for deploy in "${deploys[@]}"; do
    run_and_assert_success try "\
        at most ${POD_RETRIES} times every ${POD_RETRY_INTERVAL}s \
        to get deploy named '^${DEPLOYMENT_NAME}-${deploy}\b' \
        and verify that '.status.availableReplicas' is more than '0' \
      "
  done
}

test_services() {
  # Test the existence of Kubernetes services
  #
  # This function verifies that specified services exist in the namespace.
  # Unlike other test functions, this does not use retry logic as services
  # are typically created immediately.
  #
  # Arguments:
  #   $@ - Variable number of service names to test. Each service name should
  #        be the suffix part (without the deployment prefix) that will be
  #        combined with DEPLOYMENT_NAME to form the full service name.
  #
  # Example:
  #   test_services "rocketchat" "mongodb-headless" "redis-headless"
  #   # Tests services: ${DEPLOYMENT_NAME}-rocketchat, ${DEPLOYMENT_NAME}-mongodb-headless, etc.
  #
  # Returns:
  #   0 on success, non-zero on failure
  #   Outputs debug information on failure including current service status

  local services=("${@}")

  debug_message_on_failure \
    "Services:" \
    "$(kubectl get services -n "${DETIK_CLIENT_NAMESPACE}" -o wide)"

  for service in "${services[@]}"; do
    run_and_assert_success verify "\
      there are 1 services named '^${DEPLOYMENT_NAME}-${service}$'\
      "
  done
}

test_ingress_prop() {
  # Test specific properties of Kubernetes ingress resources
  #
  # This function verifies that ingress resources have specific property values
  # using JSONPath expressions. It supports various comparison operators
  # (is, contains, matches, etc.) for flexible property validation.
  #
  # Arguments:
  #   $@ - Variable number of space-separated strings, each containing:
  #        - ingress_name: The name of the ingress (without deployment prefix)
  #        - property: JSONPath expression to the property to test (e.g., ".spec.rules[0].host")
  #        - operator: Comparison operator (e.g., "is", "contains", "matches")
  #        - expected_value: The expected value for the property
  #
  # Example:
  #   test_ingress_prop "rocketchat .spec.rules[0].host is $ROCKETCHAT_HOST"
  #   test_ingress_prop "api .spec.tls[0].secretName is rocketchat-tls"
  #
  # Returns:
  #   0 on success, non-zero on failure
  #   Outputs debug information on failure including current ingress configuration

  debug_message_on_failure \
    "Ingresses:" \
    "$(kubectl get ingress -n "${DETIK_CLIENT_NAMESPACE}" -o wide)"

  for ingress_prop in "${@}"; do
    mapfile -d ' ' -t ingress_prop_array <<<"${ingress_prop}"
    ingress_name="${ingress_prop_array[0]}"
    property="${ingress_prop_array[1]}"
    operator="${ingress_prop_array[2]}"
    expected_value="${ingress_prop_array[3]}"

    run_and_assert_success verify "\
      '${property}' ${operator} '${expected_value}' \
      for ingress named '^${DEPLOYMENT_NAME}-${ingress_name}\b' \
    "
  done
}
