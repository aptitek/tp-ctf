#!/usr/bin/env bash
set -euo pipefail

ZONE_ID="${1:?zone id required}"
OUTPUT_PATH="${2:?output path required}"
TOKEN_FILE="/var/run/ecorp/owner.token"
PENALTY_FILE="/var/lib/ecorp/.emergency_restore.log"

read_owner_token() {
  if [[ -f "${TOKEN_FILE}" ]]; then
    tr -cd 'A-Za-z0-9._-' < "${TOKEN_FILE}" | head -c 48
  else
    printf "%s" "${TEAM_NAME:-unclaimed}"
  fi
}

detect_vault_lock() {
  local match=""
  for path in /srv/vault/.locked_by_*; do
    if [[ -f "${path}" ]]; then
      match="${path##*/.locked_by_}"
      printf "%s" "${match}" | tr -cd 'A-Za-z0-9._-' | head -c 48
      return 0
    fi
  done
  printf ""
}

collect_zone_status() {
  local sla_ok="false"
  local state="DEGRADED"
  local zombies=0
  local locked_by=""

  if /usr/local/bin/healthcheck.sh >/dev/null 2>&1; then
    sla_ok="true"
    state="UP"
  fi

  if [[ "${ZONE_ID}" == "zone-b" ]]; then
    zombies="$(ps -eo stat= | awk '$1 ~ /Z/ { c++ } END { print c + 0 }')"
    if [[ "${zombies}" -gt 0 ]]; then
      state="ZOMBIE OVERLOAD"
    fi
  fi

  if [[ "${ZONE_ID}" == "zone-c" ]]; then
    locked_by="$(detect_vault_lock)"
    if [[ -n "${locked_by}" ]]; then
      state="ENCRYPTED"
      sla_ok="false"
    fi
  fi

  local restored="false"
  if [[ -f "${PENALTY_FILE}" ]]; then
    restored="true"
  fi

  local owner=""
  owner="$(read_owner_token)"

  jq -n \
    --arg zone "${ZONE_ID}" \
    --arg owner "${owner}" \
    --arg state "${state}" \
    --arg locked_by "${locked_by}" \
    --argjson sla_ok "${sla_ok}" \
    --argjson zombies "${zombies}" \
    --argjson emergency_restored "${restored}" \
    '{
      zone: $zone,
      owner_token: $owner,
      state: $state,
      sla_ok: $sla_ok,
      zombies: $zombies,
      locked_by: $locked_by,
      emergency_restored: $emergency_restored
    }' > "${OUTPUT_PATH}.tmp"
  mv -f "${OUTPUT_PATH}.tmp" "${OUTPUT_PATH}"
}

mkdir -p "$(dirname "${TOKEN_FILE}")" "$(dirname "${OUTPUT_PATH}")"
if [[ ! -f "${TOKEN_FILE}" ]]; then
  printf "%s\n" "${TEAM_NAME:-unclaimed}" > "${TOKEN_FILE}"
fi

while true; do
  collect_zone_status
  sleep 5
done
