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

check_blocklist() {
  grep -Eq '^[[:space:]]*10\.66\.42\.199[[:space:]]*$' /etc/ecorp/blocked_ips.list 2>/dev/null
}

check_index_perms() {
  local mode=""
  mode="$(stat -c '%a' /var/www/ecorp/index.html 2>/dev/null || echo '000')"
  [[ "${mode}" == "644" || "${mode}" == "640" ]]
}

check_api_perms() {
  local mode=""
  local group=""
  mode="$(stat -c '%a' /var/www/ecorp/config/api.conf 2>/dev/null || echo '000')"
  group="$(stat -c '%G' /var/www/ecorp/config/api.conf 2>/dev/null || echo '')"
  [[ ( "${mode}" == "640" || "${mode}" == "600" ) && "${group}" == "ecorp-web" ]]
}

check_deploy_exec() {
  [[ -x /opt/ecorp/bin/deploy-check.sh ]]
}

check_http_live() {
  curl -fsS --max-time 2 http://127.0.0.1:8080/index.html >/dev/null 2>&1
}

main() {
  record_check "blocklist" check_blocklist
  record_check "index_perms" check_index_perms
  record_check "api_perms" check_api_perms
  record_check "deploy_exec" check_deploy_exec
  record_check "http_live" check_http_live

  if [[ "${1:-}" == "--report" ]]; then
    printf "%d/5|%s\n" "${PASSED}" "${DETAILS[*]}"
  fi

  [[ "${PASSED}" -eq 5 ]]
}

main "${1:-}"
