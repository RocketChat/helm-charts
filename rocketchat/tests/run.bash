#!/usr/bin/env bash
set -euo pipefail

export ROCKETCHAT_HOST="${ROCKETCHAT_HOST:-rocketchat.example.com}"
export ROCKETCHAT_TAG="${ROCKETCHAT_TAG:-7.7.1}"

function microservices() {
	echo "==========================================="
	echo "Microservices"

	export VALUES_FILE=microservices-values.yaml
	export DEPLOYMENT_NAME=rocketchat-microservices
	./bats/core/bin/bats --filter-tags !monolith rocketchat/tests/rocketchat.bats
}

function monolith() {
	echo "==========================================="
	echo "Monolith"

	export VALUES_FILE=monolith-values.yaml
	export DEPLOYMENT_NAME=rocketchat-monolith
	./bats/core/bin/bats --filter-tags !microservices rocketchat/tests/rocketchat.bats
}

echo "ROCKETCHAT_HOST: ${ROCKETCHAT_HOST}"
echo "ROCKETCHAT_TAG: ${ROCKETCHAT_TAG}"

if [[ ${#@} -eq 0 ]]; then
 tests=("microservices" "monolith")
else
 tests=("$@")
fi

for test in "${tests[@]}"; do
  "${test}"
done

echo "==========================================="
echo "Done"
