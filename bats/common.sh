#!/usr/bin/env bash

load "../../bats/bats-support/load"
load "../../bats/bats-assert/load"
load "../../bats/bats-detik/lib/detik"
load "../../bats/bats-detik/lib/linter"
load "../../bats/bats-detik/lib/utils"

run_and_assert_success() {
  debug_message_on_failure "$@"
  run "$@"
  assert_success
}

run_and_assert_failure() {
  debug_message_on_failure "$@"
  run "$@"
  assert_failure
}

# with >&3 output to stdout *even if* the test succeeded
debug_message() {
  log_debug "--------------------------------" >&3
  for i in "${@}"; do
    log_debug "${i}" >&3
  done
  log_debug "--------------------------------" >&3
}

info_message() {
  log_info "--------------------------------" >&3
  for i in "${@}"; do
    log_info "${i}" >&3
  done
  log_info "--------------------------------" >&3
}

# output to stdout *only if* the test failed
debug_message_on_failure() {
  line_separator
  for i in "${@}"; do
    log_debug "${i}"
  done
  line_separator
}

line_separator() {
  log_debug "--------------------------------"
}

log_debug() {
  while IFS= read -r line; do
    echo -e "[DEBUG]: ${line}"
  done < <(echo "$1")
}

log_info() {
  echo -e "[INFO]: $1"
}
