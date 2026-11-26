#!/usr/bin/env bash
set -euo pipefail

ZT_NET_ID="${1:-}"
TEAM_NAME="${2:-}"

if [[ -z "${ZT_NET_ID}" || -z "${TEAM_NAME}" ]]; then
  printf "Usage : mise run join -- <ZT_NETWORK_ID> <TEAM_NAME>\n"
  printf "Exemple : mise run join -- 8056c2e21c000001 fsociety-alpha\n"
  exit 1
fi

if [[ ! "${ZT_NET_ID}" =~ ^[0-9a-fA-F]{16}$ ]]; then
  printf "[ERREUR] ZT_NETWORK_ID doit contenir exactement 16 caractères hexadécimaux.\n"
  exit 1
fi

if [[ ! "${TEAM_NAME}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf "[ERREUR] TEAM_NAME ne doit contenir que lettres, chiffres, '.', '_' ou '-'.\n"
  exit 1
fi

cat > .env <<EOF
COMPOSE_PROJECT_NAME=ecorp-ops
TEAM_NAME=${TEAM_NAME}
ZEROTIER_NETWORK_ID=${ZT_NET_ID}
EOF

printf "\n[ARENA] Démarrage de l'infrastructure E-Corp pour l'équipe '%s'...\n" "${TEAM_NAME}"
docker compose --profile arena up -d --build

sleep 3

for svc in zone-a-vitrine zone-b-rh zone-c-vault; do
  docker compose exec -T "${svc}" sh -c "printf '%s\n' '${TEAM_NAME}' > /var/run/ecorp/owner.token" 2>/dev/null || true
done

node_json="$(docker compose exec -T net-bridge cat /var/lib/ecorp/arena/node.json 2>/dev/null || echo '{}')"
node_id="$(printf '%s' "${node_json}" | jq -r '.node_id // "en-cours"')"
zt_ip="$(printf '%s' "${node_json}" | jq -r '.zt_ip // "en-attente-autorisation"')"

printf "\n============================================================\n"
printf "   E-CORP ARENA — IDENTITÉ ZEROTIER DE L'ÉQUIPE\n"
printf "============================================================\n"
printf "  Équipe       : %s\n" "${TEAM_NAME}"
printf "  Réseau ZT    : %s\n" "${ZT_NET_ID}"
printf "  Node ID      : %s   <-- À communiquer au formateur !\n" "${node_id}"
printf "  IP ZeroTier  : %s\n" "${zt_ip}"
printf "  Ports NAT    : 8080 (Zone A HTTP), 2201/2202/2203 (SSH A/B/C)\n"
printf "============================================================\n\n"
