#!/usr/bin/env bash
set -euo pipefail

ZONES=(
  "zone-a-vitrine:2222"
  "zone-b-rh:2222"
  "zone-c-vault:2222"
)

printf "\n=== E-CORP NETWORK RADAR ===\n"
for entry in "${ZONES[@]}"; do
  host="${entry%%:*}"
  port="${entry##*:}"
  if nc -z -w 2 "${host}" "${port}" >/dev/null 2>&1; then
    printf "  [ONLINE ] %-16s (SSH port %s)\n" "${host}" "${port}"
  else
    printf "  [OFFLINE] %-16s (SSH port %s)\n" "${host}" "${port}"
  fi
done
printf "\nConnexion rapide : ssh zone-a | ssh zone-b | ssh zone-c\n\n"
