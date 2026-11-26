#!/usr/bin/env bash
set -euo pipefail

printf "\n=== E-CORP ARENA RADAR ===\n"

bridge_cid=""
bridge_cid="$(docker compose ps -q net-bridge 2>/dev/null || true)"

if [[ -n "${bridge_cid}" ]]; then
  node_json="$(docker compose exec -T net-bridge cat /var/lib/ecorp/arena/node.json 2>/dev/null || echo '{}')"
  team="$(printf '%s' "${node_json}" | jq -r '.team // "inconnu"')"
  node_id="$(printf '%s' "${node_json}" | jq -r '.node_id // "inconnu"')"
  zt_ip="$(printf '%s' "${node_json}" | jq -r '.zt_ip // "en-attente"')"

  printf "  Équipe      : %s\n" "${team}"
  printf "  ZT Node ID  : %s\n" "${node_id}"
  printf "  ZT IP       : %s\n" "${zt_ip}"
  printf "\n  Pairs ZeroTier visibles :\n"
  docker compose exec -T net-bridge ip neigh show 2>/dev/null | sed 's/^/    /' || true
else
  printf "  [INFO] Mode Arena inactif. Lancez : mise run join -- <ZT_NETWORK_ID> <TEAM_NAME>\n"
fi

bash scripts/status.sh
