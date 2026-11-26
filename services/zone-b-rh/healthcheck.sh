#!/usr/bin/env bash
set -euo pipefail

PASSED=0
DETAILS=()

record_check() {
  local label="${1}"
  shift
  if "$@"; then
    PASSED=$((PASSED + 1))
    DETAILS+=("${label}:OK")
  else
    DETAILS+=("${label}:FAIL")
  fi
}

check_rogue_stopped() {
  ! pgrep -f "ecorp-sync-rogue.sh" >/dev/null 2>&1
}

check_no_zombies() {
  local zombie_count=0
  zombie_count="$(ps -eo stat= | awk '$1 ~ /Z/ { c++ } END { print c + 0 }')"
  [[ "${zombie_count}" -eq 0 ]]
}

check_config_fixed() {
  grep -Eq '^[[:space:]]*REAP_CHILDREN=true[[:space:]]*$' /etc/ecorp/rh-dispatcher.conf 2>/dev/null
}

check_dispatcher_up() {
  pgrep -f "rh-dispatcher.py" >/dev/null 2>&1
}

main() {
  record_check "rogue_stopped" check_rogue_stopped
  record_check "no_zombies" check_no_zombies
  record_check "config_fixed" check_config_fixed
  record_check "dispatcher_up" check_dispatcher_up

  if [[ "${1:-}" == "--report" ]]; then
    printf "%d/4|%s\n" "${PASSED}" "${DETAILS[*]}"
  fi

  [[ "${PASSED}" -eq 4 ]]
}

main "${1:-}"
