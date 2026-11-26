#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

case "${TARGET}" in
  zone-a-vitrine|zone-b-rh|zone-c-vault)
    ;;
  *)
    printf "Usage : mise run emergency-restore -- <zone-a-vitrine|zone-b-rh|zone-c-vault>\n"
    printf "ATTENTION : Cette action inscrit un marqueur de pénalité visible par le Scorebot.\n"
    exit 1
    ;;
esac

printf "[EMERGENCY] Recréation du conteneur %s...\n" "${TARGET}"
docker compose up -d --force-recreate --no-deps "${TARGET}"
sleep 3

stamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
docker compose exec -T "${TARGET}" sh -c "printf 'EMERGENCY_RESTORE %s\n' '${stamp}' >> /var/lib/ecorp/.emergency_restore.log"

printf "[EMERGENCY] %s restauré. Marqueur de pénalité enregistré (%s).\n" "${TARGET}" "${stamp}"
bash scripts/status.sh
