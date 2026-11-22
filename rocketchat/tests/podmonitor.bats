#!/bin/bash

load "../../bats/bats-support/load"
load "../../bats/bats-assert/load"

setup() {
  CHART_DIR="${BATS_TEST_DIRNAME}/.."
}

render_podmonitor() {
  helm template test "$CHART_DIR" \
    --api-versions monitoring.coreos.com/v1 \
    --set prometheusScraping.enabled=true \
    --set nats.enabled=true \
    --show-only "templates/$1.yaml" "${@:2}"
}

@test "additional labels are rendered on both PodMonitors" {
  for template in podmonitor nats-monitor; do
    run render_podmonitor "$template" \
      --set podMonitor.additionalLabels.release=prometheus-stack \
      --set-string podMonitor.additionalLabels.team=observability
    assert_success
    assert_output --partial "kind: PodMonitor"
    assert_output --partial "    release: prometheus-stack"
    assert_output --partial "    team: observability"
    assert_output --partial "    app.kubernetes.io/name:"
    assert_equal "$(printf '%s\n' "$output" | grep -c 'release: prometheus-stack')" 1
  done
}

@test "empty additional labels preserve the default PodMonitors" {
  for template in podmonitor nats-monitor; do
    run render_podmonitor "$template"
    assert_success
    local default_output="$output"
    run render_podmonitor "$template" --set-json 'podMonitor.additionalLabels={}'
    assert_success
    assert_output "$default_output"
    refute_output --partial '{}'
  done
}

@test "additional labels do not affect the NATS fallback Service" {
  run helm template test "$CHART_DIR" \
    --set nats.enabled=true \
    --set podMonitor.additionalLabels.release=prometheus-stack \
    --show-only templates/nats-monitor.yaml
  assert_success
  assert_output --partial "kind: Service"
  refute_output --partial "release: prometheus-stack"
}
